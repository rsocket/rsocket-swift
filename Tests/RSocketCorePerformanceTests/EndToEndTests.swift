/*
 * Copyright 2015-present the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import XCTest
import NIOCore
import NIOPosix
import NIOExtras
import RSocketCore
import RSocketTestUtilities

protocol NIOServerTCPBootstrapProtocol {
    /// Bind the `ServerSocketChannel` to `host` and `port`.
    ///
    /// - parameters:
    ///     - host: The host to bind on.
    ///     - port: The port to bind on.
    func bind(host: String, port: Int) -> EventLoopFuture<Channel>
}

extension ServerBootstrap: NIOServerTCPBootstrapProtocol{}

class EndToEndTests: XCTestCase {
    static let defaultClientSetup = ClientConfiguration(
        timeout: .init(timeBetweenKeepaliveFrames: 100, maxLifetime: 1000)
    )
    
    let host = "127.0.0.1"
    
    /// Maximum count of parallel `thing`s a tests sends.
    ///
    /// What `thing` means, depends on the test e.g.:
    /// - `testRequestResponseEcho`: in flight requests
    /// - `testChannelEcho`: open channels
    /// - `test1000OpenStreamsButReceivingOnlyOnOne`: in flight payload frames on the last stream
    let maxParallelism = 6
    
    private var clientEventLoopGroup: MultiThreadedEventLoopGroup!
    private var serverEventLoopGroup: MultiThreadedEventLoopGroup!
    override func setUp() {
        clientEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        serverEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    override func tearDownWithError() throws {
        try clientEventLoopGroup.syncShutdownGracefully()
        try serverEventLoopGroup.syncShutdownGracefully()
    }
    
    func makeServerBootstrap(
        responderSocket: RSocket = TestRSocket(),
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIOServerTCPBootstrapProtocol {
        return ServerBootstrap(group: serverEventLoopGroup)
            .childChannelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                ]).flatMap {
                    channel.pipeline.addRSocketServerHandlers(
                        shouldAcceptClient: shouldAcceptClient,
                        makeResponder: { _ in responderSocket }
                    )
                }
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    }
    func makeClientBootstrap(
        responderSocket: RSocket = TestRSocket(),
        config: ClientConfiguration = EndToEndTests.defaultClientSetup,
        setupPayload: Payload = .empty,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIOClientTCPBootstrapProtocol {
        return ClientBootstrap(group: clientEventLoopGroup)
            .channelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                ]).flatMap {
                    channel.pipeline.addRSocketClientHandlers(
                        config: config,
                        setupPayload: setupPayload,
                        responder: responderSocket
                    )
                }
            }
    }
    
    override func setUpWithError() throws {
        #if DEBUG
        try XCTSkipIf(true, "performance tests should only run in release mode")
        #endif
    }
    
    func testFireAndForget() throws {
        measure {
            let requestCount = 10_000
            let requestSemaphore = DispatchSemaphore(value: maxParallelism)
            let request = self.expectation(description: "receive request")
            request.expectedFulfillmentCount = requestCount
            let server = makeServerBootstrap(responderSocket: TestRSocket(fireAndForget: { payload in
                requestSemaphore.signal()
                request.fulfill()
            }))
            let port = try! XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
            
            let requester = try! makeClientBootstrap()
                .connect(host: host, port: port)
                .flatMap(\.pipeline.requester)
                .wait()
            let payload: Payload = "Hello World"
            for _ in 0..<requestCount {
                requestSemaphore.wait()
                requester.fireAndForget(payload: payload)
            }
            self.wait(for: [request], timeout: 1)
        }
    }
    func testRequestResponseEcho() throws {
        measure {
            let requestCount = 1_000
            let requestSemaphore = DispatchSemaphore(value: maxParallelism)
            let request = self.expectation(description: "receive request")
            request.expectedFulfillmentCount = requestCount
            let server = makeServerBootstrap(responderSocket: TestRSocket(requestResponse: { payload, output in
                request.fulfill()
                // just echo back
                output.onNext(payload, isCompletion: true)
                return TestUnidirectionalStream()
            }))
            let port = try! XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
            
            let requester = try! makeClientBootstrap()
                .connect(host: host, port: port)
                .flatMap(\.pipeline.requester)
                .wait()
            
            let response = self.expectation(description: "receive response")
            response.expectedFulfillmentCount = requestCount
            let helloWorld: Payload = "Hello World"
            let input = TestUnidirectionalStream { payload, isCompletion in
                requestSemaphore.signal()
                response.fulfill()
            }
            for _ in 0..<requestCount {
                requestSemaphore.wait()
                _ = requester.requestResponse(payload: helloWorld, responderStream: input)
            }
            self.wait(for: [request, response], timeout: 5)
        }
    }
    func testChannelEcho() throws {
        measure {
            let requestCount = 1_000
            let requestSemaphore = DispatchSemaphore(value: maxParallelism)
            let request = self.expectation(description: "receive request")
            request.expectedFulfillmentCount = requestCount
            var echo: TestUnidirectionalStream?
            let server = makeServerBootstrap(responderSocket: TestRSocket(channel: { payload, initialRequestN, isCompletion, output in
                request.fulfill()
                echo = TestUnidirectionalStream.echo(to: output)
                // just echo back
                output.onNext(payload, isCompletion: false)
                return echo!
            }))
            let port = try! XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
            
            let requester = try! makeClientBootstrap()
                .connect(host: host, port: port)
                .flatMap(\.pipeline.requester)
                .wait()
            
            let response = self.expectation(description: "receive response")
            response.expectedFulfillmentCount = requestCount
            for _ in 0..<requestCount {
                requestSemaphore.wait()
                let input = TestUnidirectionalStream(
                    onNext: { _, _ in },
                    onComplete: {
                        requestSemaphore.signal()
                        response.fulfill()
                    }
                )
                let output = requester.channel(payload: "Hello", initialRequestN: .max, isCompleted: false, responderStream: input)
                output.onNext(" ", isCompletion: false)
                output.onNext("W", isCompletion: false)
                output.onNext("o", isCompletion: false)
                output.onNext("r", isCompletion: false)
                output.onNext("l", isCompletion: false)
                output.onNext("d", isCompletion: false)
                output.onComplete()
            }
            self.wait(for: [request, response], timeout: 5)
        }
    }
    func testStream() throws {
        measure {
            let requestCount = 1_000
            let requestSemaphore = DispatchSemaphore(value: maxParallelism)
            let request = self.expectation(description: "receive request")
            request.expectedFulfillmentCount = requestCount
            let server = makeServerBootstrap(responderSocket: TestRSocket(stream: { payload, initialRequestN, output in
                request.fulfill()
                output.onNext("Hello", isCompletion: false)
                output.onNext(" ", isCompletion: false)
                output.onNext("W", isCompletion: false)
                output.onNext("o", isCompletion: false)
                output.onNext("r", isCompletion: false)
                output.onNext("l", isCompletion: false)
                output.onNext("d", isCompletion: true)
                return TestUnidirectionalStream()
            }))
            let port = try! XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
            
            let requester = try! makeClientBootstrap()
                .connect(host: host, port: port)
                .flatMap(\.pipeline.requester)
                .wait()
            
            let response = self.expectation(description: "receive response")
            response.expectedFulfillmentCount = requestCount
            for _ in 0..<requestCount {
                requestSemaphore.wait()
                let input = TestUnidirectionalStream(onNext: { _, isCompletion in
                    guard isCompletion else { return }
                    requestSemaphore.signal()
                    response.fulfill()
                })
                _ = requester.stream(payload: "Hello World!", initialRequestN: .max, responderStream: input)
            }
            self.wait(for: [request, response], timeout: 1)
        }
    }
    func test1000OpenStreamsButReceivingOnlyOnOne() throws {
        measure {
            let requestCount = 1_000
            let messageCount = 10_000
            let messageSemaphore = DispatchSemaphore(value: maxParallelism)
            let request = self.expectation(description: "receive request")
            request.expectedFulfillmentCount = requestCount
            var outputs = [UnidirectionalStream]()
            outputs.reserveCapacity(requestCount)
            let server = makeServerBootstrap(responderSocket: TestRSocket(stream: { payload, initialRequestN, output in
                outputs.append(output)
                request.fulfill()
                return TestUnidirectionalStream()
            }))
            let port = try! XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
            
            let requester = try! makeClientBootstrap()
                .connect(host: host, port: port)
                .flatMap(\.pipeline.requester)
                .wait()
            
            let response = self.expectation(description: "receive response")
            response.expectedFulfillmentCount = requestCount
            let receivedMessage = self.expectation(description: "receive message from responder")
            receivedMessage.expectedFulfillmentCount = messageCount
            let initialMessage: Payload = "Hello World!"
            (0..<requestCount).forEach { _ in
                
                let input = TestUnidirectionalStream(onNext: { _, _ in
                    messageSemaphore.signal()
                    receivedMessage.fulfill()
                }, onComplete: {
                    response.fulfill()
                })
                _ = requester.stream(payload: initialMessage, initialRequestN: .max, responderStream: input)
            }
            self.wait(for: [request], timeout: 1)
            guard let firstOutput = outputs.first else {
                XCTFail("could not get first output")
                return
            }
            let messagePayload: Payload = "Hello World again..."
            for _ in 0..<messageCount {
                messageSemaphore.wait()
                firstOutput.onNext(messagePayload, isCompletion: false)
            }
            outputs.forEach({ $0.onComplete() })
            self.wait(for: [receivedMessage, response], timeout: 1)
        }
    }
}

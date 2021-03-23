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
import NIO
import NIOExtras
import RSocketCore
import RSocketTestUtilities

final class EndToEndTests: XCTestCase {
    private static let defaultClientSetup = ClientSetupConfig(
        timeBetweenKeepaliveFrames: 500,
        maxLifetime: 5000,
        metadataEncodingMimeType: "utf8",
        dataEncodingMimeType: "utf8"
    )
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    override func tearDownWithError() throws {
        try eventLoopGroup.syncShutdownGracefully()
    }
    
    let host = "127.0.0.1"
    
    func makeServerBootstrap(
        responderSocket: RSocket = TestRSocket(),
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ServerBootstrap {
        return ServerBootstrap(group: eventLoopGroup)
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
        config: ClientSetupConfig = EndToEndTests.defaultClientSetup,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIO.ClientBootstrap {
        return NIO.ClientBootstrap(group: eventLoopGroup)
            .channelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                ]).flatMap {
                    channel.pipeline.addRSocketClientHandlers(config: config, responder: responderSocket)
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
            let request = self.expectation(description: "receive request")
            request.expectedFulfillmentCount = requestCount
            let server = makeServerBootstrap(responderSocket: TestRSocket(fireAndForget: { payload in
                request.fulfill()
            }))
            let port = try! XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
            
            let requester = try! makeClientBootstrap()
                .connect(host: host, port: port)
                .flatMap(\.pipeline.requester)
                .wait()
            let payload: Payload = "Hello World"
            for _ in 0..<requestCount {
                requester.fireAndForget(payload: payload)
            }
            self.wait(for: [request], timeout: 1)
        }
    }
    func testRequestResponseEcho() throws {
        measure {
            let requestCount = 10_000
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
                response.fulfill()
            }
            for _ in 0..<requestCount {
                _ = requester.requestResponse(payload: helloWorld, responderStream: input)
            }
            self.wait(for: [request, response], timeout: 5)
        }
    }
    func testChannelEcho() throws {
        measure {
            let requestCount = 1_000
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
                let input = TestUnidirectionalStream(
                    onNext: { _, _ in },
                    onComplete: {
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
                let input = TestUnidirectionalStream(onNext: { _, isCompletion in
                    guard isCompletion else { return }
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
                firstOutput.onNext(messagePayload, isCompletion: false)
            }
            outputs.forEach({ $0.onComplete() })
            self.wait(for: [receivedMessage, response], timeout: 1)
        }
    }
}

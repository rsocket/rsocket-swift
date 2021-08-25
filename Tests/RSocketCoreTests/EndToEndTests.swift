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
import NIOEmbedded
import NIOExtras
@testable import RSocketCore
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
    static let defaultClientSetup = ClientConfiguration.mobileToServer
        .set(\.timeout.timeBetweenKeepaliveFrames, to: 100)
        .set(\.timeout.maxLifetime, to: 1000)

    let host = "127.0.0.1"
    var clientEventLoopGroup: EventLoopGroup { clientMultiThreadedEventLoopGroup as EventLoopGroup }
    private var clientMultiThreadedEventLoopGroup: MultiThreadedEventLoopGroup!
    private var serverMultiThreadedEventLoopGroup: MultiThreadedEventLoopGroup!
    
    override func setUp() {
        clientMultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        serverMultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }
    override func tearDownWithError() throws {
        try clientMultiThreadedEventLoopGroup.syncShutdownGracefully()
        try serverMultiThreadedEventLoopGroup.syncShutdownGracefully()
    }
    
    func makeServerBootstrap(
        responderSocket: RSocket = TestRSocket(),
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        maximumFrameSize: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIOServerTCPBootstrapProtocol {
        return ServerBootstrap(group: serverMultiThreadedEventLoopGroup)
            .childChannelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                ]).flatMap {
                    channel.pipeline.addRSocketServerHandlers(
                        shouldAcceptClient: shouldAcceptClient,
                        makeResponder: { _ in responderSocket },
                        maximumFrameSize: maximumFrameSize,
                        requesterLateFrameHandler: { XCTFail("server requester did receive late frame \($0)", file: file, line: line) },
                        responderLateFrameHandler: { XCTFail("server responder did receive late frame \($0)", file: file, line: line) }
                    )
                }
                // uncomment if you want to see all frames send and received
//                .flatMap {
//                    channel.pipeline.addRSocketDebugEventsHandlers(
//                        inboundName: "server receiving",
//                        outboundName: "server sending"
//                    )
//                }
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    }
    func makeClientBootstrap(
        responderSocket: RSocket = TestRSocket(),
        config: ClientConfiguration = EndToEndTests.defaultClientSetup,
        setupPayload: Payload = .empty,
        connectedPromise: EventLoopPromise<RSocket>? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIOClientTCPBootstrapProtocol {
        return ClientBootstrap(group: clientMultiThreadedEventLoopGroup)
            .channelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                ]).flatMap {
                    channel.pipeline.addRSocketClientHandlers(
                        config: config,
                        setupPayload: setupPayload,
                        responder: responderSocket,
                        connectedPromise: connectedPromise,
                        requesterLateFrameHandler: { XCTFail("client requester did receive late frame \($0)", file: file, line: line) },
                        responderLateFrameHandler: { XCTFail("client responder did receive late frame \($0)", file: file, line: line) }
                    )
                }
                // uncomment if you want to see all frames send and received
//                .flatMap {
//                    channel.pipeline.addRSocketDebugEventsHandlers(
//                        inboundName: "client receiving",
//                        outboundName: "client sending"
//                    )
//                }
            }
    }
    
    /// Bootstraps and connects a new server and client
    /// - Returns: requester socket of the connected client
    func setupAndConnectServerAndClient(
        serverResponderSocket: RSocket = TestRSocket(),
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        clientResponderSocket: RSocket = TestRSocket(),
        clientConfig: ClientConfiguration = EndToEndTests.defaultClientSetup,
        maximumFrameSize: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> RSocket {
        let server = makeServerBootstrap(
            responderSocket: serverResponderSocket,
            shouldAcceptClient: shouldAcceptClient,
            maximumFrameSize: maximumFrameSize
        )
        let serverChannel = try server.bind(host: host, port: 0).wait()
        let port = try XCTUnwrap(serverChannel.localAddress?.port)
        let clientConnected = clientEventLoopGroup.next().makePromise(of: RSocket.self)
        return try makeClientBootstrap(
            responderSocket: clientResponderSocket,
            config: clientConfig,
            connectedPromise: clientConnected
        )
        .connect(host: host, port: port)
        .flatMap({ _ in clientConnected.futureResult })
        .wait()
    }
    func testClientServerSetup() throws {
        let setup = ClientConfiguration(
            timeout: .init(
                timeBetweenKeepaliveFrames: 500,
                maxLifetime: 5000
            ), encoding: .init(
                metadata: .applicationJson,
                data: .messageXRSocketRoutingV0
            )
        )
        let clientDidConnect = self.expectation(description: "client did connect to server")
        
        let server = makeServerBootstrap(shouldAcceptClient: { clientInfo in
            XCTAssertEqual(clientInfo.timeBetweenKeepaliveFrames, Int32(setup.timeout.timeBetweenKeepaliveFrames))
            XCTAssertEqual(clientInfo.maxLifetime, Int32(setup.timeout.maxLifetime))
            XCTAssertEqual(clientInfo.encoding.metadata, setup.encoding.metadata)
            XCTAssertEqual(clientInfo.encoding.data, setup.encoding.data)
            clientDidConnect.fulfill()
            return .accept
        })
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let channel = try makeClientBootstrap(config: setup)
            .connect(host: host, port: port)
            .wait()
        XCTAssertTrue(channel.isActive)
        self.wait(for: [clientDidConnect], timeout: 1)
    }
    func testMetadataPush() throws {
        let request = self.expectation(description: "receive request")
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(metadataPush: { metadata in
                request.fulfill()
                XCTAssertEqual(metadata, ByteBuffer(string: "Hello World"))
            })
        )
        requester.metadataPush(metadata: ByteBuffer(string: "Hello World"))
        self.wait(for: [request], timeout: 1)
    }
    func testFireAndForget() throws {
        let request = self.expectation(description: "receive request")
        
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(fireAndForget: { payload in
                request.fulfill()
                XCTAssertEqual(payload, "Hello World")
            })
        )
        
        requester.fireAndForget(payload: "Hello World")
        self.wait(for: [request], timeout: 1)
    }
    func testFireAndForgetFragmentation() throws {
        let request = self.expectation(description: "receive request")
        let largePayload = Payload(
            metadata: "Some metadata which is long enough to be split into multiple frames" + repeatElement(".", count: 1500),
            data: "Some data which is just too long to be in a single frame" + repeatElement(".", count: 1500)
        )
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(fireAndForget: { payload in
                request.fulfill()
                XCTAssertEqual(payload, largePayload)
            }),
            maximumFrameSize: 500
        )
        
        requester.fireAndForget(payload: largePayload)
        self.wait(for: [request], timeout: 1)
    }
    func testRequestResponseEcho() throws {
        let request = self.expectation(description: "receive request")
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(requestResponse: { payload, output in
                request.fulfill()
                // just echo back
                output.onNext(payload, isCompletion: true)
                return TestUnidirectionalStream()
            })
        )
        
        let response = self.expectation(description: "receive response")
        let helloWorld: Payload = "Hello World"
        let input = TestUnidirectionalStream { payload, isCompletion in
            XCTAssertEqual(payload, helloWorld)
            XCTAssertTrue(isCompletion)
            response.fulfill()
        }
        _ = requester.requestResponse(payload: helloWorld, responderStream: input)
        self.wait(for: [request, response], timeout: 1)
    }
    func testRequestResponseFragmentation() throws {
        let largePayload = Payload(
            metadata: "Some metadata which is long enough to be split into multiple frames" + repeatElement(".", count: 1500),
            data: "Some data which is just too long to be in a single frame" + repeatElement(".", count: 1500)
        )
        let request = self.expectation(description: "receive request")
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(requestResponse: { payload, output in
                request.fulfill()
                XCTAssertEqual(largePayload, payload)
                // just echo back
                output.onNext(payload, isCompletion: true)
                return TestUnidirectionalStream()
            }),
            maximumFrameSize: 500
        )
        
        let response = self.expectation(description: "receive response")
        
        let input = TestUnidirectionalStream { payload, isCompletion in
            XCTAssertEqual(payload, largePayload)
            XCTAssertTrue(isCompletion)
            response.fulfill()
        }
        _ = requester.requestResponse(payload: largePayload, responderStream: input)
        self.wait(for: [request, response], timeout: 1)
    }
    func testRequestResponseError() throws {
        let request = self.expectation(description: "receive request")
        
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(requestResponse: { payload, output in
                request.fulfill()
                output.onError(.applicationError(message: "I don't like your request"))
                return TestUnidirectionalStream()
            })
        )
        
        let response = self.expectation(description: "receive response")
        let helloWorld: Payload = "Hello World"
        let input = TestUnidirectionalStream(onError: { error in
            XCTAssertEqual(error, .applicationError(message: "I don't like your request"))
            response.fulfill()
        })
        _ = requester.requestResponse(payload: helloWorld, responderStream: input)
        self.wait(for: [request, response], timeout: 1)
    }
    func testChannelEcho() throws {
        let request = self.expectation(description: "receive request")
        var echo: TestUnidirectionalStream?
        
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(channel: { payload, initialRequestN, isCompletion, output in
                request.fulfill()
                XCTAssertEqual(initialRequestN, .max)
                XCTAssertFalse(isCompletion)
                echo = TestUnidirectionalStream.echo(to: output)
                // just echo back
                output.onNext(payload, isCompletion: false)
                return echo!
            })
        )
        
        let response = self.expectation(description: "receive response")
        let input = TestUnidirectionalStream(onComplete: {
            response.fulfill()
        })
        input.failOnUnexpectedEvent = false
        let output = requester.channel(payload: "Hello", initialRequestN: .max, isCompleted: false, responderStream: input)
        output.onNext(" ", isCompletion: false)
        output.onNext("W", isCompletion: false)
        output.onNext("o", isCompletion: false)
        output.onNext("r", isCompletion: false)
        output.onNext("l", isCompletion: false)
        output.onNext("d", isCompletion: false)
        output.onComplete()
        self.wait(for: [request, response], timeout: 1)
        XCTAssertEqual(["Hello", " ", "W", "o", "r", "l", "d", .complete], input.events)
    }
    func testChannelFragmentationWithOnePayloadFragmented() throws {
        let largePayload = Payload(
            metadata: "Some metadata which is long enough to be split into multiple frames",
            data: "Some data which is just too long to be in a single frame"
        )
        let request = self.expectation(description: "receive request")
        var echo: TestUnidirectionalStream?
        
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(channel: { payload, initialRequestN, isCompletion, output in
                request.fulfill()
                XCTAssertEqual(initialRequestN, .max)
                XCTAssertFalse(isCompletion)
                echo = TestUnidirectionalStream.echo(to: output)
                // just echo back
                output.onNext(payload, isCompletion: false)
                return echo!
            }),
            maximumFrameSize: 50
        )
        
        let response = self.expectation(description: "receive response")
        let input = TestUnidirectionalStream(onNext: { payload, isComplete in
            print(isComplete, payload)
            guard isComplete else { return }
            response.fulfill()
        })
        input.failOnUnexpectedEvent = false
        let output = requester.channel(payload: "Hello", initialRequestN: .max, isCompleted: false, responderStream: input)
        output.onNext(largePayload, isCompletion: true)
        self.wait(for: [request, response], timeout: 1)
        XCTAssertEqual(
            ["Hello", .next(largePayload, isCompletion: true)],
            input.events
        )
    }
    func testChannelFragmentationWithMultipleFragmentations() throws {
        let largePayload = Payload(
            metadata: "Some metadata which is long enough to be split into multiple frames" + repeatElement(".", count: 1500),
            data: "Some data which is just too long to be in a single frame" + repeatElement(".", count: 1500)
        )
        let request = self.expectation(description: "receive request")
        var echo: TestUnidirectionalStream?
        
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(channel: { payload, initialRequestN, isCompletion, output in
                request.fulfill()
                XCTAssertEqual(initialRequestN, .max)
                XCTAssertFalse(isCompletion)
                echo = TestUnidirectionalStream.echo(to: output)
                // just echo back
                output.onNext(payload, isCompletion: false)
                return echo!
            }),
            maximumFrameSize: 500
        )
        
        let response = self.expectation(description: "receive response")
        let input = TestUnidirectionalStream(onNext: { payload, isComplete in
            print(isComplete, payload)
            guard isComplete else { return }
            response.fulfill()
        })
        input.failOnUnexpectedEvent = false
        let output = requester.channel(payload: largePayload, initialRequestN: .max, isCompleted: false, responderStream: input)
        output.onNext("1", isCompletion: false)
        output.onNext("2", isCompletion: false)
        output.onNext(largePayload, isCompletion: false)
        output.onNext("3", isCompletion: false)
        output.onNext(largePayload, isCompletion: true)
        self.wait(for: [request, response], timeout: 1)
        XCTAssertEqual(
            [.next(largePayload), "1", "2", .next(largePayload), "3", .next(largePayload, isCompletion: true)],
            input.events
        )
    }
    func testChannelResponderError() throws {
        let request = self.expectation(description: "receive request")
        
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(channel: { payload, initialRequestN, isCompletion, output in
                request.fulfill()
                XCTAssertEqual(initialRequestN, .max)
                XCTAssertFalse(isCompletion)
                
                output.onNext(payload, isCompletion: false)
                output.onError(.applicationError(message: "enough is enough"))
                
                return TestUnidirectionalStream()
            })
        )
        
        let receivedOnNext = self.expectation(description: "receive onNext")
        let receivedOnError = self.expectation(description: "receive onError")
        let input = TestUnidirectionalStream(
            onNext: { _, _ in receivedOnNext.fulfill() },
            onError: { _ in receivedOnError.fulfill() })
        let output = requester.channel(payload: "Hello", initialRequestN: .max, isCompleted: false, responderStream: input)
        self.wait(for: [request, receivedOnNext, receivedOnError], timeout: 1)
        XCTAssertEqual(input.events, ["Hello", .error(.applicationError(message: "enough is enough"))])
        
        output.onComplete() // should not send a late frame (late frames will automatically fail)
    }
    func testStream() throws {
        let request = self.expectation(description: "receive request")
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(stream: { payload, initialRequestN, output in
                request.fulfill()
                XCTAssertEqual(initialRequestN, .max)
                XCTAssertEqual(payload, "Hello World!")
                output.onNext("Hello", isCompletion: false)
                output.onNext(" ", isCompletion: false)
                output.onNext("W", isCompletion: false)
                output.onNext("o", isCompletion: false)
                output.onNext("r", isCompletion: false)
                output.onNext("l", isCompletion: false)
                output.onNext("d", isCompletion: true)
                return TestUnidirectionalStream()
            })
        )
        
        let response = self.expectation(description: "receive response")
        
        let input = TestUnidirectionalStream(onNext: { _, isCompletion in
            guard isCompletion else { return }
            response.fulfill()
        })
        _ = requester.stream(payload: "Hello World!", initialRequestN: .max, responderStream: input)
        self.wait(for: [request, response], timeout: 1)
        XCTAssertEqual(input.events, ["Hello", " ", "W", "o", "r", "l", .next("d", isCompletion: true)])
    }
    func testStreamFragmentation() throws {
        let largePayload = Payload(
            metadata: "Some metadata which is long enough to be split into multiple frames" + repeatElement(".", count: 1500),
            data: "Some data which is just too long to be in a single frame" + repeatElement(".", count: 1500)
        )
        let request = self.expectation(description: "receive request")
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(stream: { payload, initialRequestN, output in
                request.fulfill()
                XCTAssertEqual(initialRequestN, .max)
                XCTAssertEqual(payload, largePayload)
                output.onNext("1", isCompletion: false)
                output.onNext("2", isCompletion: false)
                output.onNext(largePayload, isCompletion: false)
                output.onNext("3", isCompletion: false)
                output.onNext(largePayload, isCompletion: true)
                return TestUnidirectionalStream()
            }),
            maximumFrameSize: 500
        )
        
        let response = self.expectation(description: "receive response")
        
        let input = TestUnidirectionalStream(onNext: { _, isCompletion in
            guard isCompletion else { return }
            response.fulfill()
        })
        _ = requester.stream(payload: largePayload, initialRequestN: .max, responderStream: input)
        self.wait(for: [request, response], timeout: 1)
        XCTAssertEqual(
            ["1", "2", .next(largePayload), "3", .next(largePayload, isCompletion: true)],
            input.events
        )
    }
    func testStreamError() throws {
        let request = self.expectation(description: "receive request")
        
        let requester = try setupAndConnectServerAndClient(
            serverResponderSocket: TestRSocket(stream: { payload, initialRequestN, output in
                request.fulfill()
                XCTAssertEqual(initialRequestN, .max)
                XCTAssertEqual(payload, "Hello World!")
                output.onNext("Hello", isCompletion: false)
                output.onError(.applicationError(message: "enough for today"))
                return TestUnidirectionalStream()
            })
        )
        
        let response = self.expectation(description: "receive response")
        let responseError = self.expectation(description: "receive error")
        
        let input = TestUnidirectionalStream(onNext: { payload, isCompletion in
            response.fulfill()
            XCTAssertEqual(payload, "Hello")
        }, onError: { error in
            responseError.fulfill()
            XCTAssertEqual(error, .applicationError(message: "enough for today"))
        })
        _ = requester.stream(payload: "Hello World!", initialRequestN: .max, responderStream: input)
        self.wait(for: [request, response, responseError], timeout: 1)
    }
}

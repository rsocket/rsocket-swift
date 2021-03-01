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
@testable import RSocketCore

final class TestRSocket: RSocket {
    var metadataPush: ((Payload) -> ())? = nil
    var fireAndForget: ((_ payload: Payload) -> ())? = nil
    var requestResponse: ((_ payload: Payload, _ responderOutput: UnidirectionalStream) -> Cancellable)? = nil
    var stream: ((_ payload: Payload, _ initialRequestN: Int32, _ responderOutput: UnidirectionalStream) -> Subscription)? = nil
    var channel: ((_ payload: Payload, _ initialRequestN: Int32, _ isCompleted: Bool, _ responderOutput: UnidirectionalStream) -> UnidirectionalStream)? = nil
    
    private let file: StaticString
    private let line: UInt
    
    internal init(
        metadataPush: ((Payload) -> ())? = nil,
        fireAndForget: ((Payload) -> ())? = nil,
        requestResponse: ((Payload, UnidirectionalStream) -> Cancellable)? = nil,
        stream: ((Payload, Int32, UnidirectionalStream) -> Subscription)? = nil,
        channel: ((Payload, Int32, Bool, UnidirectionalStream) -> UnidirectionalStream)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.metadataPush = metadataPush
        self.fireAndForget = fireAndForget
        self.requestResponse = requestResponse
        self.stream = stream
        self.channel = channel
        self.file = file
        self.line = line
    }
    
    
    func metadataPush(payload: Payload) {
        guard let metadataPush = metadataPush else {
            XCTFail("metadataPush not expected to be called ", file: file, line: line)
            return
        }
        metadataPush(payload)
    }
    
    func fireAndForget(payload: Payload) {
        guard let fireAndForget = fireAndForget else {
            XCTFail("fireAndForget not expected to be called ", file: file, line: line)
            return
        }
        fireAndForget(payload)
    }
    
    func requestResponse(payload: Payload, responderOutput: UnidirectionalStream) -> Cancellable {
        guard let requestResponse = requestResponse else {
            XCTFail("requestResponse not expected to be called ", file: file, line: line)
            return TestStreamInput()
        }
        return requestResponse(payload, responderOutput)
    }
    
    func stream(payload: Payload, initialRequestN: Int32, responderOutput: UnidirectionalStream) -> Subscription {
        guard let stream = stream else {
            XCTFail("stream not expected to be called ", file: file, line: line)
            return TestStreamInput()
        }
        return stream(payload, initialRequestN, responderOutput)
    }
    
    func channel(payload: Payload, initialRequestN: Int32, isCompleted: Bool, responderOutput: UnidirectionalStream) -> UnidirectionalStream {
        guard let channel = channel else {
            XCTFail("channel not expected to be called ", file: file, line: line)
            return TestStreamInput()
        }
        return channel(payload, initialRequestN, isCompleted, responderOutput)
    }
    
    
}

final class TestStreamInput: RSocketCore.UnidirectionalStream {
    enum Event: Hashable {
        case next(Payload, isCompletion: Bool)
        case error(Error)
        case complete
        case cancel
        case requestN(Int32)
        case `extension`(extendedType: Int32, payload: Payload, canBeIgnored: Bool)
    }
    private(set) var events: [Event] = []
    var onNextCallback: (_ payload: Payload, _ isCompletion: Bool) -> ()
    var onErrorCallback: (_ error: Error) -> ()
    var onCompleteCallback: () -> ()
    var onCancelCallback: () -> ()
    var onRequestNCallback: (_ requestN: Int32) -> ()
    var onExtensionCallback: (_ extendedType: Int32, _ payload: Payload, _ canBeIgnored: Bool) -> ()
    var onCompletionOrOnNextWithIsCompletionTrue: () -> ()
    
    init(
        onNext: @escaping (Payload, Bool) -> () = { _,_ in },
        onError: @escaping (Error) -> () = { _ in },
        onComplete: @escaping () -> () = {},
        onCancel: @escaping () -> () = {},
        onRequestN: @escaping (Int32) -> () = { _ in },
        onExtension: @escaping (Int32, Payload, Bool) -> () = { _,_,_ in },
        onCompletionOrOnNextWithIsCompletionTrue: @escaping () -> () = {}
    ) {
        self.onNextCallback = onNext
        self.onErrorCallback = onError
        self.onCompleteCallback = onComplete
        self.onCancelCallback = onCancel
        self.onRequestNCallback = onRequestN
        self.onExtensionCallback = onExtension
        self.onCompletionOrOnNextWithIsCompletionTrue = onCompletionOrOnNextWithIsCompletionTrue
    }
    
    func onNext(_ payload: Payload, isCompletion: Bool) {
        events.append(.next(payload, isCompletion: isCompletion))
        onNextCallback(payload, isCompletion)
        if isCompletion {
            onCompletionOrOnNextWithIsCompletionTrue()
        }
    }
    func onError(_ error: Error) {
        events.append(.error(error))
        onErrorCallback(error)
    }
    func onComplete() {
        events.append(.complete)
        onCompleteCallback()
        onCompletionOrOnNextWithIsCompletionTrue()
    }
    func onCancel() {
        events.append(.cancel)
        onCancelCallback()
    }
    func onRequestN(_ requestN: Int32) {
        events.append(.requestN(requestN))
        onRequestNCallback(requestN)
    }
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        events.append(.extension(extendedType: extendedType, payload: payload, canBeIgnored: canBeIgnored))
        onExtensionCallback(extendedType, payload, canBeIgnored)
    }
}

extension TestStreamInput {
    static func echo(to output: UnidirectionalStream) -> TestStreamInput {
        return TestStreamInput {
            output.onNext($0, isCompletion: $1)
        } onError: {
            output.onError($0)
        } onComplete: {
            output.onComplete()
        } onCancel: {
            output.onCancel()
        } onRequestN: {
            output.onRequestN($0)
        } onExtension: {
            output.onExtension(extendedType: $0, payload: $1, canBeIgnored: $2)
        }
    }
}

extension Payload: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(data: value.data(using: .utf8)!)
    }
}

extension TestStreamInput.Event: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .next(.init(stringLiteral: value), isCompletion: false)
    }
}

final class EndToEndTests: XCTestCase {
    private static let defaultClientSetup = ClientSetupConfig(
        timeBetweenKeepaliveFrames: 500,
        maxLifetime: 5000,
        metadataEncodingMimeType: "utf8",
        dataEncodingMimeType: "utf8"
    )
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
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
                    FrameDecoderHandler(),
                    FrameEncoderHandler(),
                    DebugInboundEventsHandler(),
                    DebugOutboundEventsHandler(),
                    ConnectionEstablishmentHandler(initializeConnection: { (info, channel) in
                        let sendFrame: (Frame) -> () = { [weak channel] frame in
                            channel?.writeAndFlush(frame, promise: nil)
                        }
                        return channel.pipeline.addHandlers([
                            DemultiplexerHandler(
                                connectionSide: .server,
                                requester: Requester(streamIdGenerator: .server, sendFrame: sendFrame),
                                responder: Responder(responderSocket: responderSocket, sendFrame: sendFrame)
                            ),
                            ConnectionStreamHandler(),
                        ])
                    }, shouldAcceptClient: shouldAcceptClient)
                ])
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    }
    func makeClientBootstrap(
        responderSocket: RSocket = TestRSocket(),
        config: ClientSetupConfig = EndToEndTests.defaultClientSetup,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ClientBootstrap {
        return ClientBootstrap(group: eventLoopGroup)
            .channelInitializer { (channel) -> EventLoopFuture<Void> in
                let sendFrame: (Frame) -> () = { [weak channel] frame in
                    channel?.writeAndFlush(frame, promise: nil)
                }
                return channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                    FrameDecoderHandler(),
                    FrameEncoderHandler(),
                    DebugInboundEventsHandler(),
                    DebugOutboundEventsHandler(),
                    SetupWriter(config: config),
                    DemultiplexerHandler(
                        connectionSide: .client,
                        requester: Requester(streamIdGenerator: .client, sendFrame: sendFrame),
                        responder: Responder(responderSocket: responderSocket, sendFrame: sendFrame)
                    ),
                    ConnectionStreamHandler(),
                ])
            }
    }
    func testClientServerSetup() throws {
        let setup = ClientSetupConfig(
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 5000,
            metadataEncodingMimeType: "utf8",
            dataEncodingMimeType: "utf8")
        
        let clientDidConnect = self.expectation(description: "client did connect to server")
        
        let server = makeServerBootstrap(shouldAcceptClient: { clientInfo in
            XCTAssertEqual(clientInfo.timeBetweenKeepaliveFrames, setup.timeBetweenKeepaliveFrames)
            XCTAssertEqual(clientInfo.maxLifetime, setup.maxLifetime)
            XCTAssertEqual(clientInfo.metadataEncodingMimeType, setup.metadataEncodingMimeType)
            XCTAssertEqual(clientInfo.dataEncodingMimeType, setup.dataEncodingMimeType)
            clientDidConnect.fulfill()
            return .accept
        })
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap(config: setup)
        
        let channel = try client.connect(host: host, port: port).wait()
        XCTAssertTrue(channel.isActive)
        self.wait(for: [clientDidConnect], timeout: 1)
    }
    func testFireAndForget() throws {
        let request = self.expectation(description: "receive request")
        let server = makeServerBootstrap(responderSocket: TestRSocket(fireAndForget: { payload in
            request.fulfill()
            XCTAssertEqual(payload, "Hello World")
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap()
        let channel = try client.connect(host: host, port: port).wait()
        let rsocket: RSocket = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait()
        
        rsocket.fireAndForget(payload: "Hello World")
        self.wait(for: [request], timeout: 1)
    }
    func testRequestResponseEcho() throws {
        let request = self.expectation(description: "receive request")
        let server = makeServerBootstrap(responderSocket: TestRSocket(requestResponse: { payload, output in
            request.fulfill()
            // just echo back
            output.onNext(payload, isCompletion: true)
            return TestStreamInput()
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap()
        let channel = try client.connect(host: host, port: port).wait()
        let rsocket: RSocket = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait()
        
        let response = self.expectation(description: "receive response")
        let helloWorld: Payload = "Hello World"
        let input = TestStreamInput { payload, isCompletion in
            XCTAssertEqual(payload, helloWorld)
            XCTAssertTrue(isCompletion)
            response.fulfill()
        }
        _ = rsocket.requestResponse(payload: helloWorld, responderOutput: input)
        self.wait(for: [request, response], timeout: 1)
    }
    func testChannelEcho() throws {
        let request = self.expectation(description: "receive request")
        var echo: TestStreamInput?
        let server = makeServerBootstrap(responderSocket: TestRSocket(channel: { payload, initialRequestN, isCompletion, output in
            request.fulfill()
            XCTAssertEqual(initialRequestN, .max)
            XCTAssertFalse(isCompletion)
            echo = TestStreamInput.echo(to: output)
            // just echo back
            output.onNext(payload, isCompletion: false)
            return echo!
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap()
        let channel = try client.connect(host: host, port: port).wait()
        let rsocket: RSocket = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait()
        
        let response = self.expectation(description: "receive response")
        var input: TestStreamInput!
        weak var weakInput: TestStreamInput?
        input = TestStreamInput(onComplete: {
            response.fulfill()
            XCTAssertEqual(["Hello", " ", "W", "o", "r", "l", "d", .complete], weakInput?.events)
        })
        weakInput = input
        let output = rsocket.channel(payload: "Hello", initialRequestN: .max, isCompleted: false, responderOutput: input!)
        output.onNext(" ", isCompletion: false)
        output.onNext("W", isCompletion: false)
        output.onNext("o", isCompletion: false)
        output.onNext("r", isCompletion: false)
        output.onNext("l", isCompletion: false)
        output.onNext("d", isCompletion: false)
        output.onComplete()
        self.wait(for: [request, response], timeout: 1)
    }
    func testStream() throws {
        let request = self.expectation(description: "receive request")
        let server = makeServerBootstrap(responderSocket: TestRSocket(stream: { payload, initialRequestN, output in
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
            return TestStreamInput()
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap()
        let channel = try client.connect(host: host, port: port).wait()
        let rsocket: RSocket = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait()
        
        let response = self.expectation(description: "receive response")
        var input: TestStreamInput!
        weak var weakInput: TestStreamInput?
        input = TestStreamInput(onNext: { _, isCompletion in
            guard isCompletion else { return }
            response.fulfill()
            XCTAssertEqual(["Hello", " ", "W", "o", "r", "l", .next("d", isCompletion: true)], weakInput?.events)
        })
        weakInput = input
        _ = rsocket.stream(payload: "Hello World!", initialRequestN: .max, responderOutput: input)
        self.wait(for: [request, response], timeout: 1)
    }
}

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

final class TestStreamInput: RSocketCore.StreamInput {
    enum Event: Hashable {
        case next(Payload)
        case error(Error)
        case complete
        case cancel
        case requestN(Int32)
        case `extension`(extendedType: Int32, payload: Payload, canBeIgnored: Bool)
    }
    private(set) var events: [Event] = []
    var onNextCallback: (_ payload: Payload) -> () = { _ in }
    var onErrorCallback: (_ error: Error) -> () = { _ in }
    var onCompleteCallback: () -> () = {}
    var onCancelCallback: () -> () = {}
    var onRequestNCallback: (_ requestN: Int32) -> () = { _ in }
    var onExtensionCallback: (_ extendedType: Int32, _ payload: Payload, _ canBeIgnored: Bool) -> () = { _,_,_ in }
    
    init(
        onNext: @escaping (Payload) -> () = { _ in },
        onError: @escaping (Error) -> () = { _ in },
        onComplete: @escaping () -> () = {},
        onCancel: @escaping () -> () = {},
        onRequestN: @escaping (Int32) -> () = { _ in },
        onExtension: @escaping (Int32, Payload, Bool) -> () = { _,_,_ in }
    ) {
        self.onNextCallback = onNext
        self.onErrorCallback = onError
        self.onCompleteCallback = onComplete
        self.onCancelCallback = onCancel
        self.onRequestNCallback = onRequestN
        self.onExtensionCallback = onExtension
    }
    
    func onNext(_ payload: Payload) {
        events.append(.next(payload))
        onNextCallback(payload)
    }
    func onError(_ error: Error) {
        events.append(.error(error))
        onErrorCallback(error)
    }
    func onComplete() {
        events.append(.complete)
        onCompleteCallback()
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
    static func echo(to output: StreamOutput) -> TestStreamInput {
        return TestStreamInput {
            output.sendNext($0, isCompletion: false)
        } onError: {
            output.sendError($0)
        } onComplete: {
            output.sendComplete()
        } onCancel: {
            output.sendCancel()
        } onRequestN: {
            output.sendRequestN($0)
        } onExtension: {
            output.sendExtension(extendedType: $0, payload: $1, canBeIgnored: $2)
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
        self = .next(.init(stringLiteral: value))
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
        createStream: ((StreamType, Payload, StreamOutput) -> StreamInput)? = nil,
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ServerBootstrap {
        let createStream = createStream ?? { _, _, _ in
            XCTFail("should not create a stream", file: file, line: line)
            return TestStreamInput()
        }
        return ServerBootstrap(group: eventLoopGroup)
            .childChannelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                    FrameDecoderHandler(),
                    FrameEncoderHandler(),
                    ConnectionEstablishmentHandler(initializeConnection: { (info, channel) in
                        let sendFrame: (Frame) -> () = { [weak channel] frame in
                            channel?.writeAndFlush(frame, promise: nil)
                        }
                        return channel.pipeline.addHandlers([
                            DemultiplexerHandler(
                                connectionSide: .server,
                                requester: Requester(streamIdGenerator: .server, maximumFrameSize: Payload.Constants.minMtuSize, sendFrame: sendFrame),
                                responder: Responder(maximumFrameSize: Payload.Constants.minMtuSize, createStream: createStream, sendFrame: sendFrame)
                            ),
                            ConnectionStreamHandler(),
                        ])
                    }, shouldAcceptClient: shouldAcceptClient)
                ])
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    }
    func makeClientBootstrap(
        createStream: ((StreamType, Payload, StreamOutput) -> StreamInput)? = nil,
        config: ClientSetupConfig = EndToEndTests.defaultClientSetup,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ClientBootstrap {
        let createStream = createStream ?? { _, _, _ in
            XCTFail("should not create a stream", file: file, line: line)
            return TestStreamInput()
        }
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
                    SetupWriter(config: config),
                    DemultiplexerHandler(
                        connectionSide: .client,
                        requester: Requester(streamIdGenerator: .client, maximumFrameSize: Payload.Constants.minMtuSize, sendFrame: sendFrame),
                        responder: Responder(maximumFrameSize: Payload.Constants.minMtuSize, createStream: createStream, sendFrame: sendFrame)
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
    func testRequestResponseEcho() throws {
        let server = makeServerBootstrap { type, payload, output in
            XCTAssertEqual(type, .response)
            // just echo back
            output.sendNext(payload, isCompletion: true)
            return TestStreamInput()
        }
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap()
        let channel = try client.connect(host: host, port: port).wait()
        let requester = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait().requester
        
        let response = self.expectation(description: "receive response")
        let helloWorld: Payload = "Hello World"
        let input = TestStreamInput { payload in
            XCTAssertEqual(payload, helloWorld)
            response.fulfill()
        }
        _ = requester.requestStream(for: .response, payload: helloWorld) { _ in
            input
        }
        self.wait(for: [response], timeout: 1)
    }
    func testChannelEcho() throws {
        var echo: TestStreamInput?
        let server = makeServerBootstrap { type, payload, output in
            XCTAssertEqual(type, .channel(initialRequestN: .max, isCompleted: false))
            echo = TestStreamInput.echo(to: output)
            // just echo back
            output.sendNext(payload, isCompletion: false)
            return echo!
        }
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap()
        let channel = try client.connect(host: host, port: port).wait()
        let requester = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait().requester
        
        let response = self.expectation(description: "receive response")
        var input: TestStreamInput!
        weak var weakInput: TestStreamInput?
        input = TestStreamInput(onComplete: {
            response.fulfill()
            XCTAssertEqual(["Hello", " ", "W", "o", "r", "l", "d", .complete], weakInput?.events)
        })
        weakInput = input
        let output = requester.requestStream(for: .channel(initialRequestN: .max, isCompleted: false), payload: "Hello") { _ in
            input!
        }
        output.sendNext(" ", isCompletion: false)
        output.sendNext("W", isCompletion: false)
        output.sendNext("o", isCompletion: false)
        output.sendNext("r", isCompletion: false)
        output.sendNext("l", isCompletion: false)
        output.sendNext("d", isCompletion: true)
        self.wait(for: [response], timeout: 1)
    }
    func testStream() throws {
        let server = makeServerBootstrap { type, payload, output in
            XCTAssertEqual(type, .stream(initialRequestN: .max))
            XCTAssertEqual(payload, "Hello World!")
            output.sendNext("Hello", isCompletion: false)
            output.sendNext(" ", isCompletion: false)
            output.sendNext("W", isCompletion: false)
            output.sendNext("o", isCompletion: false)
            output.sendNext("r", isCompletion: false)
            output.sendNext("l", isCompletion: false)
            output.sendNext("d", isCompletion: true)
            return TestStreamInput()
        }
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let client = makeClientBootstrap()
        let channel = try client.connect(host: host, port: port).wait()
        let requester = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait().requester
        
        let response = self.expectation(description: "receive response")
        var input: TestStreamInput!
        weak var weakInput: TestStreamInput?
        input = TestStreamInput(onComplete: {
            response.fulfill()
            XCTAssertEqual(["Hello", " ", "W", "o", "r", "l", "d", .complete], weakInput?.events)
        })
        weakInput = input
        _ = requester.requestStream(for: .stream(initialRequestN: .max), payload: "Hello World!") { _ in
            input!
        }
        self.wait(for: [response], timeout: 1)
    }
}

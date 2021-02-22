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

final class EndToEndTests: XCTestCase {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    func makeServerBootstrap(
        createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput,
        shouldAcceptClient: ClientAcceptorCallback? = nil
    ) -> ServerBootstrap {
        ServerBootstrap(group: eventLoopGroup)
            .childChannelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    /// `LengthFieldBasedFrameDecoder` and `LengthFieldBasedFrameDecoder` are part of apple/swift-nio-extra and do not yet support a lenght field lenght of 3 bytes but they are exactly what we need to support RSocket over TCP
                    // LengthFieldBasedFrameDecoder(lengthFieldLength: .three),
                    // LengthFieldPrepender(lengthFieldLength: .three),
                    RSocketFrameDecoder(),
                    RSocketFrameEncoder(),
                    ConnectionEstablishmentHandler(initializeConnection: { (info, channel) in
                        let sendFrame: (Frame) -> () = { [weak channel] frame in
                            channel?.writeAndFlush(frame, promise: nil)
                        }
                        return channel.pipeline.addHandlers([
                            DemultiplexerHandler(
                                connectionSide: .server,
                                requester: Requester(sendFrame: sendFrame),
                                responder: Responder(createStream: createStream, sendFrame: sendFrame)
                            ),
                            ConnectionStreamHandler(),
                        ])
                    }, shouldAcceptClient: shouldAcceptClient)
                ])
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    }
    func makeClientBootstrap(
        createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput,
        config: ClientSetupConfig
    ) -> ClientBootstrap {
        ClientBootstrap(group: eventLoopGroup)
            .channelInitializer { (channel) -> EventLoopFuture<Void> in
                let sendFrame: (Frame) -> () = { [weak channel] frame in
                    channel?.writeAndFlush(frame, promise: nil)
                }
                return channel.pipeline.addHandlers([
                    /// `LengthFieldBasedFrameDecoder` and `LengthFieldBasedFrameDecoder` are part of apple/swift-nio-extra and do not yet support a lenght field lenght of 3 bytes but they are exactly what we need to support RSocket over TCP
                    // LengthFieldBasedFrameDecoder(lengthFieldLength: .three),
                    // LengthFieldPrepender(lengthFieldLength: .three),
                    RSocketFrameDecoder(),
                    RSocketFrameEncoder(),
                    SetupWriter(config: config),
                    DemultiplexerHandler(
                        connectionSide: .client,
                        requester: Requester(sendFrame: sendFrame),
                        responder: Responder(createStream: createStream, sendFrame: sendFrame)
                    ),
                    ConnectionStreamHandler(),
                ])
            }
    }
    func test() throws {
        let setup = ClientSetupConfig(
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 5000,
            metadataEncodingMimeType: "utf8",
            dataEncodingMimeType: "utf8")
        
        let clientDidConnect = self.expectation(description: "client did connect to server")
        
        let server = makeServerBootstrap { type, payload, output in
            TestStreamInput.echo(to: output)
        } shouldAcceptClient: { clientInfo in
            XCTAssertEqual(clientInfo.timeBetweenKeepaliveFrames, Int(setup.timeBetweenKeepaliveFrames))
            XCTAssertEqual(clientInfo.maxLifetime, Int(setup.maxLifetime))
            XCTAssertEqual(clientInfo.metadataEncodingMimeType, setup.metadataEncodingMimeType)
            XCTAssertEqual(clientInfo.dataEncodingMimeType, setup.dataEncodingMimeType)
            clientDidConnect.fulfill()
            return .accept
        }
        XCTAssertTrue(try server.bind(host: "127.0.0.1", port: 1234).wait().isActive)
        
        let client = makeClientBootstrap(createStream: { _, _, _ in
            fatalError("should not be called")
        }, config: setup)
        let helloWorld = Payload(data: "Hello World".data(using: .utf8)!)
        let channel = try client.connect(host: "localhost", port: 1234).wait()
        XCTAssertTrue(channel.isActive)
        self.wait(for: [clientDidConnect], timeout: 1)
        
        try XCTSkipIf(true, "Not yet fully implemented")
        
        let requester = try channel.pipeline.handler(type: DemultiplexerHandler.self).wait().requester
        
        let response = self.expectation(description: "receive response")
        let input = TestStreamInput { payload in
            XCTAssertEqual(payload, helloWorld)
            response.fulfill()
        }
        _ = requester.requestStream(for: .response, payload: helloWorld) { _ in
            return input
        }
        self.wait(for: [response], timeout: 1)
    }
}

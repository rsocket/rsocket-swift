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

#if canImport(Network)
import XCTest
import NIOCore
import NIOExtras
@testable import RSocketCore
import RSocketTestUtilities
import NIOTransportServices

extension NIOTSListenerBootstrap: NIOServerTCPBootstrapProtocol{}

final class NetworkFrameworkEndToEndTests: EndToEndTests {
    override var clientEventLoopGroup: EventLoopGroup { clientNIOEventLoopGroup }
    private var clientNIOEventLoopGroup: NIOTSEventLoopGroup!
    private var serverNIOEventLoopGroup: NIOTSEventLoopGroup!
    override func setUp() {
        clientNIOEventLoopGroup = NIOTSEventLoopGroup()
        serverNIOEventLoopGroup = NIOTSEventLoopGroup()
    }
    override func tearDownWithError() throws {
        try clientEventLoopGroup.syncShutdownGracefully()
        try serverNIOEventLoopGroup.syncShutdownGracefully()
    }
    
    override func makeServerBootstrap(
        responderSocket: RSocket = TestRSocket(),
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        maximumFrameSize: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIOServerTCPBootstrapProtocol {
        NIOTSListenerBootstrap(group: serverNIOEventLoopGroup)
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
            }
    }
    override func makeClientBootstrap(
        responderSocket: RSocket = TestRSocket(),
        config: ClientConfiguration = EndToEndTests.defaultClientSetup,
        setupPayload: Payload = .empty,
        connectedPromise: EventLoopPromise<RSocket>? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIOClientTCPBootstrapProtocol {
        NIOTSConnectionBootstrap(group: clientEventLoopGroup)
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
            }
    }
}
#endif

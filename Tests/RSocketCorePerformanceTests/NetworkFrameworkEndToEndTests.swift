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
import RSocketCore
import RSocketTestUtilities
import NIOTransportServices

extension NIOTSListenerBootstrap: NIOServerTCPBootstrapProtocol{}

final class NetworkFrameworkEndToEndTests: EndToEndTests {
    private var clientEventLoopGroup: NIOTSEventLoopGroup!
    private var serverEventLoopGroup: NIOTSEventLoopGroup!
    override func setUp() {
        clientEventLoopGroup = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .userInteractive)
        serverEventLoopGroup = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .userInteractive)
    }
    override func tearDownWithError() throws {
        try clientEventLoopGroup.syncShutdownGracefully()
        try serverEventLoopGroup.syncShutdownGracefully()
    }
    
    override func makeServerBootstrap(
        responderSocket: RSocket = TestRSocket(),
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIOServerTCPBootstrapProtocol {
        NIOTSListenerBootstrap(group: serverEventLoopGroup)
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
    }
    override func makeClientBootstrap(
        responderSocket: RSocket = TestRSocket(),
        config: ClientConfiguration = EndToEndTests.defaultClientSetup,
        setupPayload: Payload = .empty,
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
                        responder: responderSocket
                    )
                }
            }
    }
}
#endif

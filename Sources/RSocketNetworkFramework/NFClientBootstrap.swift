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

import Network
import NIO
import NIOTransportServices
import RSocketCore

public struct NFClientBootstrap {
    private let group = NIOTSEventLoopGroup()
    private let bootstrap: NIOTSConnectionBootstrap
    private let config: ClientSetupConfig
    private let transport: TransportChannelHandler

    public init(
        config: ClientSetupConfig,
        transport: TransportChannelHandler,
        timeout: TimeAmount = .seconds(30),
        tlsOptions: NWProtocolTLS.Options? = nil
    ) {
        self.config = config
        bootstrap = NIOTSConnectionBootstrap(group: group)
            .connectTimeout(timeout)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        if let tlsOptions = tlsOptions {
            _ = bootstrap.tlsOptions(tlsOptions)
        }
        self.transport = transport
    }

    @discardableResult
    public func configure(bootstrap configure: (NIOTSConnectionBootstrap) -> NIOTSConnectionBootstrap) -> Self {
        _ = configure(bootstrap)
        return self
    }
}

extension NFClientBootstrap: RSocketCore.ClientBootstrap {
    public func connect(host: String, port: Int, responder: RSocketCore.RSocket?) -> EventLoopFuture<CoreClient> {
        let requesterPromise = group.next().makePromise(of: RSocketCore.RSocket.self)

        let connectFuture = bootstrap
            .channelInitializer { channel in
                transport.addChannelHandler(channel: channel, host: host, port: port) {
                    channel.pipeline.addRSocketClientHandlers(
                        config: config,
                        responder: responder,
                        connectedPromise: requesterPromise
                    )
                }
            }
            .connect(host: host, port: port)

        return connectFuture
            .flatMap { _ in requesterPromise.futureResult }
            .map(CoreClient.init)
    }
}

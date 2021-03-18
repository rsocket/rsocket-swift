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

import NIO
import NIOSSL
import RSocketCore

public struct FoundationClientBootstrap {
    private let group: EventLoopGroup
    private let bootstrap: NIO.ClientBootstrap
    private let config: ClientSetupConfig
    private let transport: TransportChannelHandler
    private let sslContext: NIOSSLContext?

    public init(
        group: EventLoopGroup,
        config: ClientSetupConfig,
        transport: TransportChannelHandler,
        timeout: TimeAmount = .seconds(30),
        sslContext: NIOSSLContext? = nil
    ) {
        self.group = group
        self.config = config
        bootstrap = ClientBootstrap(group: group)
            .connectTimeout(timeout)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        self.sslContext = sslContext
        self.transport = transport
    }

    public init(
        config: ClientSetupConfig,
        transport: TransportChannelHandler,
        numberOfThreads: Int = 1,
        timeout: TimeAmount = .seconds(30),
        sslContext: NIOSSLContext? = nil
    ) {
        self.init(
            group: MultiThreadedEventLoopGroup(numberOfThreads: numberOfThreads),
            config: config,
            transport: transport,
            timeout: timeout,
            sslContext: sslContext
        )
    }

    @discardableResult
    public func configure(bootstrap configure: (NIO.ClientBootstrap) -> NIO.ClientBootstrap) -> Self {
        _ = configure(bootstrap)
        return self
    }
}

extension TSClientBootstrap: RSocketCore.ClientBootstrap {
    public func connect(host: String, port: Int, responder: RSocketCore.RSocket?) -> EventLoopFuture<CoreClient> {
        let requesterPromise = group.next().makePromise(of: RSocketCore.RSocket.self)

        let connectFuture = bootstrap
            .channelInitializer { channel in
                let otherHandlersBlock: () -> EventLoopFuture<Void> = {
                    transport.addChannelHandler(channel: channel, host: host, port: port) {
                        channel.pipeline.addRSocketClientHandlers(
                            config: config,
                            responder: responder,
                            connectedPromise: requesterPromise
                        )
                    }
                }
                if let sslContext = sslContext {
                    do {
                        let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: host)
                        return channel.pipeline.addHandler(sslHandler).flatMap(otherHandlersBlock)
                    } catch {
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                } else {
                    return otherHandlersBlock()
                }
            }
            .connect(host: host, port: port)

        return connectFuture
            .flatMap { _ in requesterPromise.futureResult }
            .map(CoreClient.init)
    }
}

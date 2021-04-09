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

final public class ClientBootstrap<Transport: TransportChannelHandler> {
    private let group: EventLoopGroup
    private let bootstrap: NIO.ClientBootstrap
    private let config: ClientConfiguration
    private let transport: Transport
    private let sslContext: NIOSSLContext?

    public init(
        transport: Transport,
        config: ClientConfiguration,
        timeout: TimeAmount = .seconds(30),
        sslContext: NIOSSLContext? = nil
    ) {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.config = config
        bootstrap = NIO.ClientBootstrap(group: group)
            .connectTimeout(timeout)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        self.sslContext = sslContext
        self.transport = transport
    }

    @discardableResult
    public func configure(bootstrap configure: (NIO.ClientBootstrap) -> NIO.ClientBootstrap) -> Self {
        _ = configure(bootstrap)
        return self
    }
}

extension ClientBootstrap: RSocketCore.ClientBootstrap {
    static func makeDefaultSSLContext() throws -> NIOSSLContext {
        try .init(configuration: .clientDefault)
    }
    public func connect(
        to endpoint: Transport.Endpoint,
        payload: Payload,
        responder: RSocketCore.RSocket?
    ) -> EventLoopFuture<CoreClient> {
        let requesterPromise = group.next().makePromise(of: RSocketCore.RSocket.self)
        
        let connectFuture = bootstrap
            .channelInitializer { [transport, config, sslContext] channel in
                let otherHandlersBlock: () -> EventLoopFuture<Void> = {
                    transport.addChannelHandler(
                        channel: channel,
                        maximumIncomingFragmentSize: config.limits.maximumIncomingFragmentSize,
                        endpoint: endpoint
                    ) {
                        channel.pipeline.addRSocketClientHandlers(
                            config: config,
                            setupPayload: payload,
                            responder: responder,
                            connectedPromise: requesterPromise
                        )
                    }
                }
                if sslContext != nil || endpoint.requiresTLS {
                    do {
                        let context = try sslContext ?? Self.makeDefaultSSLContext()
                        let sslHandler = try NIOSSLClientHandler(context: context, serverHostname: endpoint.host)
                        return channel.pipeline.addHandler(sslHandler).flatMap(otherHandlersBlock)
                    } catch {
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                } else {
                    return otherHandlersBlock()
                }
            }
            .connect(host: endpoint.host, port: endpoint.port)

        return connectFuture
            .flatMap { _ in requesterPromise.futureResult }
            .map(CoreClient.init)
    }
}

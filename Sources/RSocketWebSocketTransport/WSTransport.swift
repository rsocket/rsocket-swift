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
import NIOHTTP1
import NIOWebSocket
import RSocketCore

public struct WSTransport {
    public init() { }
}

extension WSTransport: TransportChannelHandler {
    public func addChannelHandler(
        channel: Channel,
        host: String,
        port: Int,
        upgradeComplete: @escaping () -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        let httpHandler = HTTPInitialRequestHandler(host: host, port: port)
        let websocketUpgrader = NIOWebSocketClientUpgrader(
            requestKey: "OfS0wDaT5NoxF2gqm7Zj2YtetzM=", // TODO
            upgradePipelineHandler: { _, _ in
                upgradeComplete()
            }
        )
        let config: NIOHTTPClientUpgradeConfiguration = (
            upgraders: [websocketUpgrader],
            completionHandler: { _ in
                channel.pipeline.removeHandler(httpHandler, promise: nil)
            }
        )
        return channel.pipeline
            .addHTTPClientHandlers(withClientUpgrade: config)
            .flatMap { channel.pipeline.addHandler(httpHandler) }
    }
}

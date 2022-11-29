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

import Foundation
import NIOCore
import NIOHTTP1
import NIOWebSocket
import RSocketCore

public struct WSTransport {
    public struct Endpoint {
        public var url: URL
        public var additionalHTTPHeader: [String: String]
        public init(url: URL, additionalHTTPHeader: [String : String] = [:]) {
            self.url = url
            self.additionalHTTPHeader = additionalHTTPHeader
        }
    }

    private let minNonFinalFragmentSize: Int
    private let maxAccumulatedFrameCount: Int

    /// WebSocket Transport for RSocket
    /// - Parameters:
    ///   - minNonFinalFragmentSize: Minimum size in bytes of a fragment which is not the last fragment of a complete frame. Used to defend agains many really small payloads. Default is `0`.
    ///   - maxAccumulatedFrameCount: Maximum number of fragments which are allowed to result in a complete frame. Defaults to `Int.max`
    ///   - Note: Maximum accumulated size in bytes of buffered fragments is configured through `ClientConfiguration.Fragmentation`
    public init(
        minNonFinalFragmentSize: Int = 0,
        maxAccumulatedFrameCount: Int = Int.max
    ) {
        self.minNonFinalFragmentSize = minNonFinalFragmentSize
        self.maxAccumulatedFrameCount = maxAccumulatedFrameCount
    }
}

extension WSTransport.Endpoint: Endpoint {
    private static let secureScheme = "wss"
    private static let insecureDefaultPort = 80
    private static let secureDefaultPort = 443
    public var host: String { url.host ?? "" }
    public var port: Int { url.port ?? defaultPort }
    public var requiresTLS: Bool { url.scheme?.lowercased() == Self.secureScheme }
    private var defaultPort: Int {
        url.scheme?.lowercased() == Self.secureScheme ? Self.secureDefaultPort : Self.insecureDefaultPort
    }
    
    internal var uri: String {
        var uri = url.path
        /// URI is not allowed to be empty according to RFC 2616 Section 5.1.2 Request-URI https://tools.ietf.org/html/rfc2616#page-36
        if uri.isEmpty {
            uri = "/"
        }
        if let query = url.query, !query.isEmpty {
            uri += "?" + query
        }
        return uri
    }
}

extension WSTransport: TransportChannelHandler {
    public func addChannelHandler(channel: Channel, maximumIncomingFragmentSize: Int, endpoint: Endpoint, upgradeComplete: @escaping () -> EventLoopFuture<Void>, resultHandler : @escaping (Result<Void, Swift.Error>) -> EventLoopFuture<Void>) -> EventLoopFuture<Void> {
        let httpHandler = HTTPInitialRequestHandler(
            host: endpoint.host,
            port: endpoint.port,
            uri: endpoint.uri,
            additionalHTTPHeader: endpoint.additionalHTTPHeader,
            completionhandler: resultHandler
        )
        let websocketUpgrader = NIOWebSocketClientUpgrader(
            maxFrameSize: maximumIncomingFragmentSize,
            upgradePipelineHandler: { channel, _ in
                channel.pipeline.addHandlers([
                    NIOWebSocketFrameAggregator(
                        minNonFinalFragmentSize: minNonFinalFragmentSize,
                        maxAccumulatedFrameCount: maxAccumulatedFrameCount,
                        maxAccumulatedFrameSize: maximumIncomingFragmentSize
                    ),
                    WebSocketFrameToByteBuffer(),
                    WebSocketFrameFromByteBuffer(),
                ])
                .flatMap(upgradeComplete)
            }
        )
        let config: NIOHTTPClientUpgradeConfiguration = (
            upgraders: [websocketUpgrader],
            completionHandler: { _ in
                channel.pipeline.removeHandler(httpHandler, promise: nil)
            }
        )
        return channel.pipeline.addHTTPClientHandlers(withClientUpgrade: config)
            .flatMap { channel.pipeline.addHandler(httpHandler) }
    }
}

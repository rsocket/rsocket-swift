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
import NIO
import NIOHTTP1
import NIOWebSocket
import RSocketCore

/// generates 16 bytes randomly and encodes them as a base64 string as defined in RFC6455 https://tools.ietf.org/html/rfc6455#section-4.1
/// - Returns: base64 encoded string
fileprivate func randomRequestKey() -> String {
    /// we may want to use `randomBytes(count:)` once the proposal is accepted: https://forums.swift.org/t/pitch-requesting-larger-amounts-of-randomness-from-systemrandomnumbergenerator/27226
    let lower = UInt64.random(in: UInt64.min...UInt64.max)
    let upper = UInt64.random(in: UInt64.min...UInt64.max)
    let data = withUnsafeBytes(of: lower) { lowerBytes in
        withUnsafeBytes(of: upper) { upperBytes in
            Data(lowerBytes) + Data(upperBytes)
        }
    }
    return data.base64EncodedString()
}

public struct WSTransport {
    public struct Endpoint {
        public var url: URL
        public var additionalHTTPHeader: [String: String]
        public init(url: URL, additionalHTTPHeader: [String : String] = [:]) {
            self.url = url
            self.additionalHTTPHeader = additionalHTTPHeader
        }
    }
    public init() {}
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
    public func addChannelHandler(
        channel: Channel,
        endpoint: Endpoint,
        upgradeComplete: @escaping () -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        let httpHandler = HTTPInitialRequestHandler(
            host: endpoint.host,
            port: endpoint.port,
            uri: endpoint.uri,
            additionalHTTPHeader: endpoint.additionalHTTPHeader
        )
        let websocketUpgrader = NIOWebSocketClientUpgrader(
            requestKey: randomRequestKey(),
            upgradePipelineHandler: { channel, _ in
                channel.pipeline.addHandlers([
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

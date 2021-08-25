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

/// The role of a connection
internal enum ConnectionRole {
    /// The side initiating a connection
    case client
    /// The side accepting connections from clients
    case server
}

extension StreamID {
    fileprivate var generatedBy: ConnectionRole? {
        guard self != .connection else { return nil }
        return rawValue.isMultiple(of: 2) ? .server : .client
    }
}

internal struct DemultiplexerRouter {
    internal struct Route: OptionSet {
        internal static let connection = Route(rawValue: 1 << 0)
        internal static let requester = Route(rawValue: 1 << 1)
        internal static let responder = Route(rawValue: 1 << 2)
        internal static let all: Route = [connection, requester, responder]

        internal let rawValue: UInt8
    }
    
    internal var connectionSide: ConnectionRole
    
    internal func route(for streamId: StreamID, type: FrameType) -> Route {
        switch (streamId.generatedBy, connectionSide) {
        case (nil, _):
            switch type {
            case .metadataPush:
                return .responder
            case .error:
                return .all
            default:
                return .connection
            }
        case (.client, .client), (.server, .server):
            return .requester
        case (.client, .server), (.server, .client):
            return .responder
        }
    }
}

internal final class DemultiplexerHandler: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias InboundOut = Frame
    
    private let router: DemultiplexerRouter
    let requester: Requester
    let responder: Responder
    
    internal init(connectionSide: ConnectionRole, requester: Requester, responder: Responder) {
        self.router = .init(connectionSide: connectionSide)
        self.requester = requester
        self.responder = responder
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        let route = router.route(for: frame.streamId, type: frame.body.type)
        if route.contains(.connection) {
            context.fireChannelRead(wrapInboundOut(frame))
        }
        if route.contains(.requester) {
            requester.receiveInbound(frame: frame)
        }
        if route.contains(.responder) {
            responder.receiveInbound(frame: frame)
        }
    }
}

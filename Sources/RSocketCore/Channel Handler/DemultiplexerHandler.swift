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
    internal enum Route {
        case connection
        case requester
        case responder
    }
    
    internal var connectionSide: ConnectionRole
    
    internal func route(for streamId: StreamID) -> Route {
        switch (streamId.generatedBy, connectionSide) {
        case (nil, _):
            return .connection
        case (.client, .client), (.server, .server):
            return .responder
        case (.client, .server), (.server, .client):
            return .requester
        }
    }
}

internal final class DemultiplexerHandler: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias InboundOut = Frame
    
    private let router: DemultiplexerRouter
    private let requester: Requester
    private let responder: Responder
    
    internal init(connectionSide: ConnectionRole, requester: Requester, responder: Responder) {
        self.router = .init(connectionSide: connectionSide)
        self.requester = requester
        self.responder = responder
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch router.route(for: frame.header.streamId) {
        case .connection:
            context.fireChannelRead(wrapInboundOut(frame))
        case .requester:
            requester.receiveInbound(frame: frame)
        case .responder:
            responder.receiveInbound(frame: frame)
        }
    }
}
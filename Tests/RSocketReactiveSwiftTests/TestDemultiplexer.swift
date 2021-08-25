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

import XCTest
import NIOEmbedded
@testable import RSocketCore

struct TestDemultiplexer {
    let router: DemultiplexerRouter
    let requester: Requester
    let responder: Responder
    
    internal init(connectionSide: ConnectionRole, requester: Requester, responder: Responder) {
        self.router = .init(connectionSide: connectionSide)
        self.requester = requester
        self.responder = responder
    }
    
    func receiveFrame(frame: Frame) {
        let route = router.route(for: frame.streamId, type: frame.body.type)
        if route.contains(.connection) {
            XCTFail("connection message not expected \(frame)")
        }
        if route.contains(.requester) {
            requester.receiveInbound(frame: frame)
        }
        if route.contains(.responder) {
            responder.receiveInbound(frame: frame)
        }
    }
}

extension TestDemultiplexer {
    static func pipe(
        serverResponder: RSocketCore.RSocket?,
        clientResponder: RSocketCore.RSocket?
    ) -> (server: TestDemultiplexer, client: TestDemultiplexer) {
        let serverResponder = serverResponder ?? DefaultRSocket(encoding: .default)
        let clientResponder = clientResponder ?? DefaultRSocket(encoding: .default)
        var client: TestDemultiplexer!
        let eventLoop = EmbeddedEventLoop()
        let server = TestDemultiplexer(
            connectionSide: .server,
            requester: .init(streamIdGenerator: .server, encoding: .default, eventLoop: eventLoop, sendFrame: { frame in
                client.receiveFrame(frame: frame)
            }),
            responder: .init(responderSocket: serverResponder, eventLoop: eventLoop, sendFrame: { frame in
                client.receiveFrame(frame: frame)
            }))
        client = TestDemultiplexer(
            connectionSide: .client,
            requester: .init(streamIdGenerator: .client, encoding: .default, eventLoop: eventLoop, sendFrame: { frame in
                server.receiveFrame(frame: frame)
            }),
            responder: .init(responderSocket: clientResponder, eventLoop: eventLoop, sendFrame: { frame in
                server.receiveFrame(frame: frame)
            }))
        return (server, client!)
    }
}

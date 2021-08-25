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
import NIOCore
import NIOEmbedded
@testable import RSocketCore


fileprivate final class TestClock {
    var time: TimeInterval = 7000
    func getTime() -> TimeInterval {
        return time
    }
    func advance(by incrementTime: TimeInterval) {
        self.time += incrementTime
    }
    func reset() {
        self.time = 7000
    }
}

final class KeepaliveHandlerTests: XCTestCase {
    func testKeepAliveRespondBack() throws {
        let channel = EmbeddedChannel(handler: KeepaliveHandler(timeBetweenKeepaliveFrames: 1, maxLifetime: 2, connectionSide: ConnectionRole.server))

        let frame = KeepAliveFrameBody(respondWithKeepalive: true, lastReceivedPosition: 0, data: ByteBuffer()).asFrame()
        try channel.writeInbound(frame)

        XCTAssertEqual(
            try channel.readOutbound(as: Frame.self)?.body.type, .keepalive,
            "Should have received KeepAliveFrame in response"
        )
        XCTAssertTrue(try channel.finish().isClean)
    }

    func testKeepAliveNoResponseBack() throws {
        let channel = EmbeddedChannel(handler: KeepaliveHandler(timeBetweenKeepaliveFrames: 1, maxLifetime: 2, connectionSide: ConnectionRole.client))

        let frame = KeepAliveFrameBody(respondWithKeepalive: false, lastReceivedPosition: 0, data: ByteBuffer()).asFrame()
        try channel.writeInbound(frame)

        XCTAssertNil(try channel.readOutbound(as: Frame.self), "Shouldn't have received a KeepAliveFrame in response")
        XCTAssertTrue(try channel.finish().isClean)
    }
    
    func testKeepAliveTimeout() throws {
        let clock = TestClock()
        let loop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(
            handler: KeepaliveHandler(
                timeBetweenKeepaliveFrames: 1_000,
                maxLifetime: 4_000,
                connectionSide: ConnectionRole.client,
                now: clock.getTime
            ),
            loop: loop
        )
        
        try channel.connect(to: SocketAddress.init(ipAddress: "127.0.0.1", port: 0)).wait()
        
        XCTAssertNil(try channel.readOutbound(as: Frame.self), "should not timeout immediately")
        
        clock.advance(by: 1)
        loop.advanceTime(by: .seconds(1))
        XCTAssertEqual(try channel.readOutbound(as: Frame.self)?.body.type, .keepalive)
        
        clock.advance(by: 1)
        loop.advanceTime(by: .seconds(1))
        XCTAssertEqual(try channel.readOutbound(as: Frame.self)?.body.type, .keepalive)
        
        clock.advance(by: 1)
        loop.advanceTime(by: .seconds(1))
        XCTAssertEqual(try channel.readOutbound(as: Frame.self)?.body.type, .keepalive)
        
        clock.advance(by: 1)
        loop.advanceTime(by: .seconds(1))
        let frame = try XCTUnwrap(try channel.readOutbound(as: Frame.self))
        switch frame.body {
        case let .error(body):
            XCTAssertEqual(body.error.code, .connectionClose)
        default:
            XCTFail("connection should be closed but \(frame) was send")
        }
        
        XCTAssertTrue(try channel.finish().isClean)
    }
    
    func testSendingOfKeepAliveFrameAfterTimeBetweenKeepaliveFrames() throws {
        let clock = TestClock()
        let loop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(
            handler: KeepaliveHandler(
                timeBetweenKeepaliveFrames: 500,
                maxLifetime: 2000,
                connectionSide: ConnectionRole.client,
                now: clock.getTime
            ),
            loop: loop
        )
        try channel.connect(to: SocketAddress.init(ipAddress: "127.0.0.1", port: 0)).wait()
        
        clock.advance(by: 0.5)
        loop.advanceTime(by: .milliseconds(500))
        
        XCTAssertEqual(
            try channel.readOutbound(as: Frame.self),
            KeepAliveFrameBody(respondWithKeepalive: true, lastReceivedPosition: 0, data: ByteBuffer()).asFrame(),
            "Should send KeepAliveFrame"
        )
        XCTAssertTrue(try channel.finish().isClean)
    }
}

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
import NIO
@testable import RSocketCore

extension StreamID: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int32) {
        self.init(rawValue: value)
    }
}

fileprivate final class TestClock {
    var time: TimeInterval = 0
    func getTime() -> TimeInterval {
        return time
    }
    func advance(by incrementTime: TimeInterval) {
        self.time += incrementTime
    }
    func reset() {
        self.time = 0
    }
}

final class ConnectionEstablishmentTests: XCTestCase {
    func testSuccessfulEstablishment() throws {
        let initializeConnection = self.expectation(description: "should initialize connection")
        initializeConnection.assertForOverFulfill = true
        
        let shouldAcceptSetup = self.expectation(description: "shouldAcceptSetup should be called")
        shouldAcceptSetup.assertForOverFulfill = true
        
        
        let channel = EmbeddedChannel(
            handler: ConnectionEstablishmentHandler(initializeConnection: { (info, channel) in
                initializeConnection.fulfill()
                return channel.eventLoop.makeSucceededFuture(())
            }, shouldAcceptClient: { (info) -> ClientAcceptorResult in
                shouldAcceptSetup.fulfill()
                return .accept
            }))
        
        try channel.writeInbound(SetupFrameBody(
            honorsLease: false,
            version: .v1_0,
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 10000,
            resumeIdentificationToken: nil,
            metadataEncodingMimeType: "utf8",
            dataEncodingMimeType: "utf8",
            payload: .empty
        ).asFrame())
        
        XCTAssertThrowsError(
            try channel.pipeline.handler(type: ConnectionEstablishmentHandler.self).wait(),
            "handler should be removed"
        )
        
        self.wait(for: [initializeConnection, shouldAcceptSetup], timeout: 0.1)
    }
    
    func testKeepAliveRespondBack() throws {
        let channel = EmbeddedChannel(handler: ConnectionStreamHandler(timeBetweenKeepaliveFrames: 1, maxLifetime: 2, connectionSide: ConnectionRole.server))

        let frame = KeepAliveFrameBody(respondWithKeepalive: true, lastReceivedPosition: 0, data: Data()).asFrame()
        try channel.writeInbound(frame)

        XCTAssertEqual(
            try channel.readOutbound(as: Frame.self)?.header.type, .keepalive,
            "Should have received KeepAliveFrame in response"
        )
        XCTAssertTrue(try channel.finish().isClean)
    }

    func testKeepAliveNoResponseBack() throws {
        let channel = EmbeddedChannel(handler: ConnectionStreamHandler(timeBetweenKeepaliveFrames: 1, maxLifetime: 2, connectionSide: ConnectionRole.client))

        let frame = KeepAliveFrameBody(respondWithKeepalive: false, lastReceivedPosition: 0, data: Data()).asFrame()
        try channel.writeInbound(frame)

        XCTAssertNil(try channel.readOutbound(as: Frame.self), "Shouldn't have received a KeepAliveFrame in response")
        XCTAssertTrue(try channel.finish().isClean)
    }
    
    func testKeepAliveTimeout() throws {
        let clock = TestClock()
        let loop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(
            handler: ConnectionStreamHandler(
                timeBetweenKeepaliveFrames: 10,
                maxLifetime: 10,
                connectionSide: ConnectionRole.client,
                now: clock.getTime
            ),
            loop: loop
        )
        
        try channel.connect(to: SocketAddress.init(ipAddress: "127.0.0.1", port: 0)).wait()
        
        XCTAssertNil(try channel.readOutbound(as: Frame.self), "should not timeout immediately")
        
        clock.advance(by: 0.009)
        loop.advanceTime(by: .milliseconds(9))
        XCTAssertNil(try channel.readOutbound(as: Frame.self), "should not timeout right before timeout")
        
        clock.advance(by: 0.001)
        loop.advanceTime(by: .milliseconds(1))
        let frame = try XCTUnwrap(try channel.readOutbound(as: Frame.self))
        switch frame.body {
        case let .error(body):
            XCTAssertEqual(body.error.kind, .connectionClose)
        default:
            XCTFail("connection should be closed but \(frame) was send")
        }
        
        XCTAssertTrue(try channel.finish().isClean)
    }
    
    func testSendingOfKeepAliveFrameAfterTimeBetweenKeepaliveFrames() throws {
        let clock = TestClock()
        let loop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(
            handler: ConnectionStreamHandler(
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
            KeepAliveFrameBody(respondWithKeepalive: true, lastReceivedPosition: 0, data: Data()).asFrame(),
            "Should send KeepAliveFrame"
        )
        XCTAssertTrue(try channel.finish().isClean)
    }

    func testDeliveryOfExtraMessagesDuringSetup() throws {
        let loop = EmbeddedEventLoop()
        let connectionInitialization = loop.makePromise(of: Void.self)
        
        let channel = EmbeddedChannel(
            handler: ConnectionEstablishmentHandler(initializeConnection: { _, _ in
                connectionInitialization.futureResult
            }), loop: loop)
        
        try channel.writeInbound(SetupFrameBody(
            honorsLease: false,
            version: .v1_0,
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 10000,
            resumeIdentificationToken: nil,
            metadataEncodingMimeType: "utf8",
            dataEncodingMimeType: "utf8",
            payload: .empty
        ).asFrame())
        
        let frame = RequestResponseFrameBody(payload: .empty)
            .asFrame(withStreamId: 3)
        try channel.writeInbound(frame)
        
        connectionInitialization.completeWith(.success(()))
        
        XCTAssertEqual(try channel.readInbound(as: Frame.self), frame)
    }
}

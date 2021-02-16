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
            }, shouldAcceptSetup: { (info) -> ClientAcceptorResult in
                shouldAcceptSetup.fulfill()
                return .accept
            }))
        let frameBody = SetupFrameBody(
            honorsLease: false,
            version: .v0_2,
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 10000,
            resumeIdentificationToken: nil,
            metadataEncodingMimeType: "utf8",
            dataEncodingMimeType: "utf8",
            payload: .empty
        )
        let frame = Frame(header: frameBody.header(), body: .setup(frameBody))
        try channel.writeInbound(frame)
        
        XCTAssertThrowsError(
            try channel.pipeline.handler(type: ConnectionEstablishmentHandler.self).wait(),
            "handler should be removed"
        )
        
        self.wait(for: [initializeConnection, shouldAcceptSetup], timeout: 0.1)
    }
    
    
    func testDeliveryOfExtraMessagesDuringSetup() throws {
        let loop = EmbeddedEventLoop()
        let connectionInitialization = loop.makePromise(of: Void.self)
        
        let channel = EmbeddedChannel(
            handler: ConnectionEstablishmentHandler(initializeConnection: { _, _ in
                connectionInitialization.futureResult
            }), loop: loop)
        let setupFrameBody = SetupFrameBody(
            honorsLease: false,
            version: .v0_2,
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 10000,
            resumeIdentificationToken: nil,
            metadataEncodingMimeType: "utf8",
            dataEncodingMimeType: "utf8",
            payload: .empty
        )
        let setupFrame = Frame(header: setupFrameBody.header(), body: .setup(setupFrameBody))
        try channel.writeInbound(setupFrame)
        
        let frameBody = RequestResponseFrameBody(fragmentsFollow: false, payload: .empty)
        let frame = Frame(header: frameBody.header(withStreamId: .init(rawValue: 3)), body: .requestResponse(frameBody))
        try channel.writeInbound(frame)
        
        connectionInitialization.completeWith(.success(()))
        
        XCTAssertNotNil(try channel.readInbound(as: Frame.self))
    }
}

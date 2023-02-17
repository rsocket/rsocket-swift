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
import XCTest
@testable import RSocketCore

final class SetupFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         5, 64, 0, 1,
                                         0, 1, 0, 0,
                                         0, 10, 0, 0,
                                         0, 10, 10, 116,
                                         101, 120, 116, 47,
                                         112, 108, 97, 105,
                                         110, 10, 116, 101,
                                         120, 116, 47, 112,
                                         108, 97, 105, 110,
                                         0, 0, 1, 109,
                                         100]

    /* Test Setup Frame initialisation with honorsLease, majorVersion, minorVersion,
     * timeBetweenKeepaliveFrames, maxLifetime, resumeIdentificationToken,
     * metadataEncodingMimeType, dataEncodingMimeType and payload.
     * Verify that the frame is initialised with expected values.
     */
    func testSetupFrameInit() {
        let resumeIdentificationToken = "resumeIdentificationToken".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let payloadMetadata = "test payload metadata".data(using: .utf8)!

        let setupFrame = SetupFrame(honorsLease: true, majorVersion: 2, minorVersion: 0, timeBetweenKeepaliveFrames: 10, maxLifetime: 10, resumeIdentificationToken: resumeIdentificationToken, metadataEncodingMimeType: "text/plain", dataEncodingMimeType: "text/plain", payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(setupFrame.header.type, .setup, "Expected setup frame type")
        XCTAssert(setupFrame.header.flags.rawValue & FrameFlags.setupLease.rawValue != 0, "Expected lease flag to be set")
        XCTAssert(setupFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssert(setupFrame.header.flags.rawValue & FrameFlags.setupResume.rawValue != 0, "Expected resume flag to be set")
        XCTAssertEqual(setupFrame.majorVersion, 2)
        XCTAssertEqual(setupFrame.minorVersion, 0)
        XCTAssertEqual(setupFrame.timeBetweenKeepaliveFrames, 10)
        XCTAssertEqual(setupFrame.maxLifetime, 10)
        XCTAssertEqual(setupFrame.dataEncodingMimeType, "text/plain")
        XCTAssertEqual(setupFrame.metadataEncodingMimeType, "text/plain")
        XCTAssertEqual(setupFrame.payload.data, payloadData)
        XCTAssertEqual(setupFrame.payload.metadata, payloadMetadata)
    }

    /* Test Setup Frame Encoder.
     * Encode a setup frame and check the bytes in encoded byte buffer.
     */
    func testSetupFrameHeaderEncoder() {
        let payloadData = "d".data(using: .utf8)!
        let payloadMetadata = "m".data(using: .utf8)!

        let setupFrame = SetupFrame(honorsLease: true, majorVersion: 1, minorVersion: 1, timeBetweenKeepaliveFrames: 10, maxLifetime: 10, resumeIdentificationToken: nil, metadataEncodingMimeType: "text/plain", dataEncodingMimeType: "text/plain", payload: Payload(metadata: payloadMetadata, data: payloadData))

        guard var byteBuffer = try? SetupFrameEncoder().encode(frame: setupFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }
        XCTAssertEqual(byteBuffer.readableBytes, 45)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), SetupFrameTests.bytes)
    }

    /* Test for Setup Frame Decoder.
     * Verify that the decoded byte buffer is setup frame.
     */
    func testSetupFrameHeaderDecoder() {
        var byteBuffer = ByteBuffer(bytes: SetupFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedSetupFrame = try? SetupFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedSetupFrame.header.type, .setup, "Expected setup frame type")
        XCTAssertTrue(decodedSetupFrame.header.flags.rawValue & FrameFlags.setupLease.rawValue != 0, "Expected lease flag to be set")
        XCTAssertEqual(decodedSetupFrame.header.flags.rawValue & FrameFlags.setupResume.rawValue, 0, "Expected resume flag to not be set")
        XCTAssertEqual(decodedSetupFrame.majorVersion, 1)
        XCTAssertEqual(decodedSetupFrame.minorVersion, 1)
        XCTAssertEqual(decodedSetupFrame.timeBetweenKeepaliveFrames, 10)
        XCTAssertEqual(decodedSetupFrame.maxLifetime, 10)
        XCTAssertEqual(decodedSetupFrame.dataEncodingMimeType, "text/plain")
        XCTAssertEqual(decodedSetupFrame.metadataEncodingMimeType, "text/plain")
        XCTAssertEqual(decodedSetupFrame.payload.data, "d".data(using: .utf8)!)
        XCTAssertEqual(decodedSetupFrame.payload.metadata, "m".data(using: .utf8)!)
    }

    /* Test for Setup Frame Coding.
     * This test encodes setup frame and gets the byte buffer.
     * Then decodes the byte buffer using setup frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testSetupFrameCoder() {
        let resumeIdentificationToken = "resumeIdentificationToken".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let payloadMetadata = "test payload metadata".data(using: .utf8)!

        let setupFrame = SetupFrame(honorsLease: true, majorVersion: 2, minorVersion: 0, timeBetweenKeepaliveFrames: 10, maxLifetime: 10, resumeIdentificationToken: resumeIdentificationToken, metadataEncodingMimeType: "text/plain", dataEncodingMimeType: "text/plain", payload: Payload(metadata: payloadMetadata, data: payloadData))

        guard var byteBuffer = try? SetupFrameEncoder().encode(frame: setupFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedSetupFrame = try? SetupFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedSetupFrame.header.type, .setup, "Expected Setup frame type")
        XCTAssertEqual(decodedSetupFrame.timeBetweenKeepaliveFrames, 10)
        XCTAssertEqual(decodedSetupFrame.payload.metadata, payloadMetadata)
    }

    func testSetupFrameHonorsLeaseFalse() {
        let resumeIdentificationToken = "resumeIdentificationToken".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let payloadMetadata = "test payload metadata".data(using: .utf8)!

        let setupFrame = SetupFrame(honorsLease: false, majorVersion: 2, minorVersion: 0, timeBetweenKeepaliveFrames: 10, maxLifetime: 10, resumeIdentificationToken: resumeIdentificationToken, metadataEncodingMimeType: "text/plain", dataEncodingMimeType: "text/plain", payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(setupFrame.header.type, .setup, "Expected setup frame type")
        XCTAssert(setupFrame.header.flags.rawValue & FrameFlags.setupLease.rawValue == 0, "Expected lease flag to not be set")
    }

    func testSetupFrameResumeIdTokenNil() {
        let payloadData = "test payload data".data(using: .utf8)!
        let payloadMetadata = "test payload metadata".data(using: .utf8)!

        let setupFrame = SetupFrame(honorsLease: false, majorVersion: 2, minorVersion: 0, timeBetweenKeepaliveFrames: 10, maxLifetime: 10, resumeIdentificationToken: nil, metadataEncodingMimeType: "text/plain", dataEncodingMimeType: "text/plain", payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(setupFrame.header.type, .setup, "Expected setup frame type")
        XCTAssert(setupFrame.header.flags.rawValue & FrameFlags.setupResume.rawValue == 0, "Expected lease flag to not be set")
        XCTAssertEqual(setupFrame.resumeIdentificationToken, nil, "Expected resume identification token to be nil")
    }
}

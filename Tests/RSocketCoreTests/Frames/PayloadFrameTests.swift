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

final class PayloadFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 1,
                                         41, 224, 0, 0,
                                         1, 109, 100]

    /* Test Payload Frame initialisation.
     * Verify that the frame is initialised with expected header and payload.
     */
    func testPayloadInit() {
        let payloadMetadata = "test payload metadata".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssertEqual(payloadFrame.header.streamId, 1)
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadComplete.rawValue != 0, "Expected complete flag to be set")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadNext.rawValue != 0, "Expected next flag to be set")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(payloadFrame.payload.data, payloadData)
        XCTAssertEqual(payloadFrame.payload.metadata, payloadMetadata)
    }

    /* Test Payload Frame Encoder.
     * Encode a payload frame and check the bytes in encoded byte buffer.
     */
    func testPayloadEncoder() {
        let payloadMetadata = "m".data(using: .utf8)!
        let payloadData = "d".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(metadata: payloadMetadata, data: payloadData))

        guard var byteBuffer = try? PayloadFrameEncoder().encode(frame: payloadFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 11)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), PayloadFrameTests.bytes)
    }

    /* Test for Payload Frame Decoder.
     * Verify that the decoded byte buffer is payload frame.
     */
    func testPayloadFrameDecoder() {
        var byteBuffer = ByteBuffer(bytes: PayloadFrameTests.bytes)
        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedPayloadFrame = try? PayloadFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedPayloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssertEqual(decodedPayloadFrame.header.streamId, 1)
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.payloadFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.payloadComplete.rawValue != 0, "Expected complete flag to be set")
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.payloadNext.rawValue != 0, "Expected next flag to be set")
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedPayloadFrame.payload.data, "d".data(using: .utf8)!)
        XCTAssertEqual(decodedPayloadFrame.payload.metadata, "m".data(using: .utf8)!)
    }

    /* Test for Payload Frame Coding.
     * This test encodes payload frame and gets the byte buffer.
     * Then decodes the byte buffer using payload frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testPayloadFrameCoder() {
        let payloadMetadata = "test payload metadata".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 2, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(metadata: payloadMetadata, data: payloadData))

        guard var byteBuffer = try? PayloadFrameEncoder().encode(frame: payloadFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedPayloadFrame = try? PayloadFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedPayloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssertEqual(decodedPayloadFrame.header.streamId, 2)
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.payloadFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.payloadComplete.rawValue != 0, "Expected complete flag to be set")
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.payloadNext.rawValue != 0, "Expected next flag to be set")
        XCTAssert(decodedPayloadFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedPayloadFrame.payload.data, payloadData)
        XCTAssertEqual(decodedPayloadFrame.payload.metadata, payloadMetadata)
    }

    /* Test for Payload Frame follow flag set.
     * Follow flag should be set if fragmentsFollow is true.
     */
    func testPayloadFollowsFlagSet() {
        let payloadData = "".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadFollows.rawValue != 0, "Expected follows flag to be set")
    }

    func testPayloadFollowsFlagNotSet() {
        let payloadData = "".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: false, isCompletion: true, isNext: true, payload: Payload(data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadFollows.rawValue == 0, "Expected follows flag to not be set")
    }

    /* Test for Payload Frame metadata flag set.
     * Metadata flag should be set if metadata is present in the payload.
     */
    func testPayloadMetadata() {
        let payloadMetadata = "m".data(using: .utf8)!
        let payloadData = "d".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
    }

    func testPayloadMetadataNil() {
        let payloadData = "d".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.metadata.rawValue == 0, "Expected metadata flag to not be set")
    }

    /* Test for Payload Frame complete flag set.
     * Complete flag should be set if isCompletion is true.
     */
    func testPayloadComplete() {
        let payloadData = "d".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadComplete.rawValue != 0, "Expected complete flag to be set")
    }

    func testPayloadCompleteFalse() {
        let payloadData = "d".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: false, isNext: true, payload: Payload(data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadComplete.rawValue == 0, "Expected complete flag to not be set")
    }

    /* Test for Payload Frame next flag set.
     * Next flag should be set if isNext is true.
     */
    func testPayloadNextFlagSet() {
        let payloadData = "".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: true, isCompletion: true, isNext: true, payload: Payload(data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadNext.rawValue != 0, "Expected next flag to be set")
    }

    func testPayloadNextFlagNotSet() {
        let payloadData = "".data(using: .utf8)!
        let payloadFrame = PayloadFrame(streamId: 1, fragmentsFollow: false, isCompletion: true, isNext: false, payload: Payload(data: payloadData))

        XCTAssertEqual(payloadFrame.header.type, .payload, "Expected payload frame type")
        XCTAssert(payloadFrame.header.flags.rawValue & FrameFlags.payloadNext.rawValue == 0, "Expected next flag to not be set")
    }
}

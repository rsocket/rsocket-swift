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

/* This class has tests for Cancel Frame. */
final class CancelFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         36, 0]

    /* Test Cancel Frame initialisation with streamId.
     * Verify that the frame is initialised with expected values.
     */
    func testCancelFrameInit() {
        let cancelFrame = CancelFrame(streamId: 0)

        XCTAssertEqual(cancelFrame.header.streamId, 0)
        XCTAssertEqual(cancelFrame.header.type, .cancel, "Expected cancel frame type")
        XCTAssertTrue(cancelFrame.header.flags.isEmpty, "Expected flags to be empty")
    }

    /* Test Cancel Frame initialisation with FrameHeader.
     * Verify that the frame is initialised with expected values.
     */
    func testCancelFrameInitWithFrameHeader() {
        let cancelFrame = CancelFrame(header: FrameHeader(streamId: 0, type: .cancel, flags: FrameFlags(rawValue: 6)))

        XCTAssertEqual(cancelFrame.header.streamId, 0)
        XCTAssertEqual(cancelFrame.header.type, .cancel, "Expected cancel frame type")
        XCTAssertEqual(cancelFrame.header.flags, FrameFlags(rawValue: 6), "Expected flags to be not empty")
    }

    /* Test Cancel Frame Encoder.
     * Encode a cancel frame with streamId and check the bytes in encoded byte buffer.
     */
    func testCancelFrameHeaderEncoder() {
        guard var byteBuffer = try? CancelFrameEncoder().encode(frame: CancelFrame(streamId: 0), using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 6)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), CancelFrameTests.bytes)
    }

    /* Test for Cancel Frame Decoder.
     * Verify that the decoded byte buffer is a cancel frame.
     */
    func testCancelFrameHeaderDecoder() {
        var byteBuffer = ByteBuffer(bytes: CancelFrameTests.bytes)
        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedCancelFrame = try? CancelFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedCancelFrame.header.type, .cancel, "Expected cancel frame type")
        XCTAssertTrue(decodedCancelFrame.header.flags.isEmpty, "Expected flags to be empty")
    }

    /* Test for Cancel Frame Coding.
     * This test encodes cancel frame and gets the byte buffer.
     * Then decodes the byte buffer using cancel frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testCancelFrameCoder() {
        guard var byteBuffer = try? CancelFrameEncoder().encode(frame: CancelFrame(streamId: 0), using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedCancelFrame = try? CancelFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedCancelFrame.header.type, .cancel, "Expected cancel frame type")
        XCTAssertTrue(decodedCancelFrame.header.flags.isEmpty, "Expected flags to be empty")
    }
}

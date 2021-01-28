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

final class ResumeOkFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         56, 0, 0, 0,
                                         0, 0, 0, 0,
                                         0, 6]

    /* Test Resume Ok Frame initialisation with lastReceivedClientPosition.
     * Verify that the frame is initialised with expected values.
     */
    func testResumeOkInit() {
        let resumeOkFrame = ResumeOkFrame(lastReceivedClientPosition: 5)

        XCTAssertEqual(resumeOkFrame.header.type, .resumeOk, "Expected resume Ok frame type")
        XCTAssertEqual(resumeOkFrame.header.streamId, 0, "Expected steam id 0 in resume Ok frame type")
        XCTAssertTrue(resumeOkFrame.header.flags.isEmpty, "Expected flags to be empty")
        XCTAssertEqual(resumeOkFrame.lastReceivedClientPosition, 5)
    }

    func testResumeOkFramePassValidation() {
        let resumeOkFrame = ResumeOkFrame(lastReceivedClientPosition: 5)

        XCTAssertNoThrow(try resumeOkFrame.validate())
    }

    func testResumeOkFrameFailValidation() {
        let resumeOkFrame = ResumeOkFrame(lastReceivedClientPosition: -1)

        XCTAssertThrowsError(try resumeOkFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "lastReceivedClientPosition has to be equal or bigger than 0")
        }
    }

    /* Test Resume Ok Frame Encoder.
     * Encode a resume ok frame and check the bytes in encoded byte buffer.
     */
    func testResumeOkEncoder() {
        let resumeOkFrame = ResumeOkFrame(lastReceivedClientPosition: 6)

        guard var byteBuffer = try? ResumeOkFrameEncoder().encode(frame: resumeOkFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }
        XCTAssertEqual(byteBuffer.readableBytes, 14)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), ResumeOkFrameTests.bytes)
    }

    /* Test for Resume Ok Frame Decoder.
     * Verify that the decoded byte buffer is resume ok frame.
     */
    func testResumeOkDecoder() {
        var byteBuffer = ByteBuffer(bytes: ResumeOkFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedResumeOkFrame = try? ResumeOkFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedResumeOkFrame.header.type, .resumeOk, "Expected resume Ok frame type")
        XCTAssertEqual(decodedResumeOkFrame.header.streamId, 0, "Expected steam id 0 in resume Ok frame type")
        XCTAssertTrue(decodedResumeOkFrame.header.flags.isEmpty, "Expected flags to be empty")
        XCTAssertEqual(decodedResumeOkFrame.lastReceivedClientPosition, 6)
    }

    /* Test for Resume Ok Frame Coding.
     * This test encodes resume ok frame and gets the byte buffer.
     * Then decodes the byte buffer using resume ok frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testResumeOkFrameCoder() {
        let resumeOkFrame = ResumeOkFrame(lastReceivedClientPosition: 5)

        guard var byteBuffer = try? ResumeOkFrameEncoder().encode(frame: resumeOkFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedResumeOkFrame = try? ResumeOkFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedResumeOkFrame.header.type, .resumeOk, "Expected resume Ok frame type")
        XCTAssertEqual(decodedResumeOkFrame.header.streamId, 0, "Expected steam id 0 in resume Ok frame type")
        XCTAssertTrue(decodedResumeOkFrame.header.flags.isEmpty, "Expected flags to be empty")
        XCTAssertEqual(decodedResumeOkFrame.lastReceivedClientPosition, 5)
    }
}

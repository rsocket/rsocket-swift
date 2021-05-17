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

final class ResumeFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         52, 0, 0, 1,
                                         0, 2, 0, 1,
                                         114, 0, 0, 0,
                                         0, 0, 0, 0,
                                         4, 0, 0, 0,
                                         0, 0, 0, 0,
                                         5]

    /* Test Resume Frame initialisation with majorVersion, minorVersion,
     * resumeIdentificationToken, lastReceivedServerPosition and firstAvailableClientPosition.
     * Verify that the frame is initialised with expected values.
     */
    func testResumeInit() {
        let resumeIdentificationToken = "resumeIdentificationToken".data(using: .utf8)!
        let resumeFrame = ResumeFrame(majorVersion: 1, minorVersion: 2, resumeIdentificationToken: resumeIdentificationToken, lastReceivedServerPosition: 4, firstAvailableClientPosition: 5)

        XCTAssertEqual(resumeFrame.header.type, .resume, "Expected resume frame type")
        XCTAssertEqual(resumeFrame.header.streamId, 0, "Expected steam id 0 in resume frame type")
        XCTAssertTrue(resumeFrame.header.flags.isEmpty, "Expected flags to be empty")
        XCTAssertEqual(resumeFrame.majorVersion, 1)
        XCTAssertEqual(resumeFrame.minorVersion, 2)
        XCTAssertEqual(resumeFrame.resumeIdentificationToken, resumeIdentificationToken)
        XCTAssertEqual(resumeFrame.lastReceivedServerPosition, 4)
        XCTAssertEqual(resumeFrame.firstAvailableClientPosition, 5)
    }

    func testResumeFramePassValidation() {
        let resumeIdentificationToken = "resumeIdentificationToken".data(using: .utf8)!
        let resumeFrame = ResumeFrame(majorVersion: 1, minorVersion: 2, resumeIdentificationToken: resumeIdentificationToken, lastReceivedServerPosition: 4, firstAvailableClientPosition: 5)

        XCTAssertNoThrow(try resumeFrame.validate())
    }

    func testResumeFrameFailValidation() {
        let resumeIdentificationToken = "resumeIdentificationToken".data(using: .utf8)!
        let resumeFrame = ResumeFrame(majorVersion: 1, minorVersion: 2, resumeIdentificationToken: resumeIdentificationToken, lastReceivedServerPosition: 4, firstAvailableClientPosition: -1)

        XCTAssertThrowsError(try resumeFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "firstAvailableClientPosition has to be equal or bigger than 0")
        }
    }

    /* Test Resume Frame Encoder.
     * Encode a resume frame and check the bytes in encoded byte buffer.
     */
    func testResumeEncoder() {
        let resumeIdentificationToken = "r".data(using: .utf8)!
        let resumeFrame = ResumeFrame(majorVersion: 1, minorVersion: 2, resumeIdentificationToken: resumeIdentificationToken, lastReceivedServerPosition: 4, firstAvailableClientPosition: 5)

        guard var byteBuffer = try? ResumeFrameEncoder().encode(frame: resumeFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 29)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), ResumeFrameTests.bytes)
    }

    /* Test for Resume Frame Decoder.
     * Verify that the decoded byte buffer is resume frame.
     */
    func testResumeDecoder() {
        var byteBuffer = ByteBuffer(bytes: ResumeFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedResumeFrame = try? ResumeFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedResumeFrame.header.type, .resume, "Expected resume frame type")
        XCTAssertEqual(decodedResumeFrame.header.streamId, 0, "Expected steam id 0 in resume frame type")
        XCTAssertTrue(decodedResumeFrame.header.flags.isEmpty, "Expected flags to be empty")
        XCTAssertEqual(decodedResumeFrame.majorVersion, 1)
        XCTAssertEqual(decodedResumeFrame.minorVersion, 2)
        XCTAssertEqual(decodedResumeFrame.resumeIdentificationToken, "r".data(using: .utf8)!)
        XCTAssertEqual(decodedResumeFrame.lastReceivedServerPosition, 4)
        XCTAssertEqual(decodedResumeFrame.firstAvailableClientPosition, 5)
    }

    /* Test for Resume Frame Coding.
     * This test encodes resume frame and gets the byte buffer.
     * Then decodes the byte buffer using resume frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testResumeFrameCoder() {
        let resumeIdentificationToken = "resumeIdentificationToken".data(using: .utf8)!
        let resumeFrame = ResumeFrame(majorVersion: 1, minorVersion: 2, resumeIdentificationToken: resumeIdentificationToken, lastReceivedServerPosition: 4, firstAvailableClientPosition: 5)

        guard var byteBuffer = try? ResumeFrameEncoder().encode(frame: resumeFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedResumeFrame = try? ResumeFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedResumeFrame.header.type, .resume, "Expected resume frame type")
        XCTAssertEqual(decodedResumeFrame.header.streamId, 0, "Expected steam id 0 in resume frame type")
        XCTAssertTrue(decodedResumeFrame.header.flags.isEmpty, "Expected flags to be empty")
        XCTAssertEqual(decodedResumeFrame.majorVersion, 1)
        XCTAssertEqual(decodedResumeFrame.minorVersion, 2)
        XCTAssertEqual(decodedResumeFrame.resumeIdentificationToken, resumeIdentificationToken)
        XCTAssertEqual(decodedResumeFrame.lastReceivedServerPosition, 4)
        XCTAssertEqual(decodedResumeFrame.firstAvailableClientPosition, 5)
    }
}

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

final class ErrorFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         44, 6, 0, 0,
                                         0, 111, 116, 101,
                                         115, 116, 32, 101,
                                         114, 114, 111, 114]

    /* Test Error Frame initialisation with a streamId and error.
     * Verify that the frame is initialised with expected values.
     */
    func testErrorFrameInit() {
        let error = Error.other(code: 111, message: "test error")
        let errorFrame = ErrorFrame(streamId: 0, error: error)

        XCTAssertEqual(errorFrame.header.type, .error, "Expected error frame type")
        XCTAssertEqual(errorFrame.header.streamId, 0)
        XCTAssertTrue(errorFrame.header.flags.isEmpty)
        XCTAssertEqual(errorFrame.error.code, error.code)
        XCTAssertEqual(errorFrame.error.message, error.message)

    }

    /* Test Error Frame initialisation with FrameHeader.
     * Verify that the frame is initialised with expected values.
     */
    func testErrorFrameInitWithFrameHeader() {
        let error = Error.other(code: 111, message: "test error")
        let errorFrame = ErrorFrame(header: FrameHeader(streamId: 0, type: .error, flags: FrameFlags(rawValue: 6)), error: error)

        XCTAssertEqual(errorFrame.header.type, .error, "Expected error frame type")
        XCTAssertEqual(errorFrame.header.streamId, 0)
        XCTAssertEqual(errorFrame.header.flags, FrameFlags(rawValue: 6))
        XCTAssertEqual(errorFrame.error.code, error.code)
        XCTAssertEqual(errorFrame.error.message, error.message)
    }

    /* Test for valid Error Frame. */
    func testErrorFramePassValidation() {
        let error = Error.applicationError(message: "test error")
        let errorFrame = ErrorFrame(streamId: 2, error: error)

        XCTAssertNoThrow(try errorFrame.validate())
    }

    /* Test for invalid Error Frame. */
    func testErrorFrameFailValidation() {
        let error = Error.other(code: 111, message: "test error")
        let errorFrame = ErrorFrame(streamId: 0, error: error)

        XCTAssertThrowsError(try errorFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "The given error code is not valid for this streamId")
        }
    }

    /* Test Error Frame Encoder.
     * Encode an error frame with streamId, flags and error.
     * Verfiy that the encode bytes are as expected.
     */
    func testErrorFrameHeaderEncoder() {
        let error = Error.other(code: 111, message: "test error")

        guard var byteBuffer = try? ErrorFrameEncoder().encode(frame: ErrorFrame(header: FrameHeader(streamId: 0, type: .error, flags: FrameFlags(rawValue: 6)), error: error), using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 20)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), ErrorFrameTests.bytes)
    }

    /* Test for Error Frame Decoder.
     * Verify that the decoded byte buffer is an error frame.
     * Verify that the error code and message is as expected.
     */
    func testErrorFrameHeaderDecoder() {
        var byteBuffer = ByteBuffer(bytes: ErrorFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedErrorFrame = try? ErrorFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedErrorFrame.header.type, .error, "Expected error frame type")
        XCTAssertEqual(decodedErrorFrame.header.streamId, 0)
        XCTAssertEqual(decodedErrorFrame.error.code, 111)
        XCTAssertEqual(decodedErrorFrame.error.message, "test error")
    }

    /* Test for Error Frame Coding.
     * This test encodes error frame and gets the byte buffer.
     * Then decodes the byte buffer using error frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testErrorFrameCoder() {
        let error = Error.other(code: 111, message: "test")

        guard var byteBuffer = try? ErrorFrameEncoder().encode(frame: ErrorFrame(header: FrameHeader(streamId: 0, type: .error, flags: FrameFlags(rawValue: 6)), error: error), using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedErrorFrame = try? ErrorFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedErrorFrame.header.type, .error, "Expected error frame type")
        XCTAssertEqual(decodedErrorFrame.header.streamId, 0)
        XCTAssertEqual(decodedErrorFrame.error.code, 111)
        XCTAssertEqual(decodedErrorFrame.error.message, "test")
    }
}

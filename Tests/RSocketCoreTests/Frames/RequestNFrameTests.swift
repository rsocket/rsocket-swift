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

final class RequestNFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 1,
                                         32, 0, 0, 0,
                                         0, 12]

    /* Test Request N Frame initialisation with streamId and requestN.
     * Verify that the frame is initialised with expected values.
     */
    func testRequestNInit() {
        let requestNFrame = RequestNFrame(streamId: 1, requestN: 11)

        XCTAssertEqual(requestNFrame.header.type, .requestN, "Expected request N frame type")
        XCTAssertEqual(requestNFrame.requestN, 11)
    }

    func testRequestNFramePassValidation() {
        let requestNFrame = RequestNFrame(streamId: 1, requestN: 11)

        XCTAssertNoThrow(try requestNFrame.validate())
    }

    func testRequestNFrameFailValidation() {
        let requestNFrame = RequestNFrame(streamId: 1, requestN: 0)

        XCTAssertThrowsError(try requestNFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "requestN has to be bigger than 0")
        }
    }

    /* Test Request N Frame Encoder.
     * Encode a request N frame and check the bytes in encoded byte buffer.
     */
    func testRequestNEncoder() {
        let requestNFrame = RequestNFrame(streamId: 1, requestN: 12)

        guard var byteBuffer = try? RequestNFrameEncoder().encode(frame: requestNFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }
        XCTAssertEqual(byteBuffer.readableBytes, 10)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), RequestNFrameTests.bytes)
    }

    /* Test for Request N Frame Decoder.
     * Verify that the decoded byte buffer is request N frame.
     */
    func testRequestNFrameDecoder() {
        var byteBuffer = ByteBuffer(bytes: RequestNFrameTests.bytes)
        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestNFrame = try? RequestNFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestNFrame.header.type, .requestN, "Expected request N frame type")
        XCTAssertEqual(decodedRequestNFrame.requestN, 12)
    }

    /* Test for Request N Frame Coding.
     * This test encodes request N frame and gets the byte buffer.
     * Then decodes the byte buffer using request N frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testRequestNFrameCoder() {
        let requestNFrame = RequestNFrame(streamId: 1, requestN: 14)

        guard var byteBuffer = try? RequestNFrameEncoder().encode(frame: requestNFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestNFrame = try? RequestNFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestNFrame.header.type, .requestN, "Expected request N frame type")
        XCTAssertEqual(decodedRequestNFrame.requestN, 14)
    }
}

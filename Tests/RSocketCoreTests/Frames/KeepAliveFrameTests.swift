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

final class KeepAliveFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         12, 128, 0, 0,
                                         0, 0, 0, 0,
                                         0, 10, 100 ]

    /* Test Keep Alive Frame initialisation with respondWithKeepalive, lastReceivedPosition, data.
     * Verify that the frame is initialised with expected values.
     */
    func testKeepAliveInit() {
        let frameData = "test data".data(using: .utf8)!
        let keepAliveFrame = KeepAliveFrame(respondWithKeepalive: true, lastReceivedPosition: 10, data: frameData)

        XCTAssertEqual(keepAliveFrame.header.type, .keepalive, "Expected keep alive frame type")
        XCTAssert(keepAliveFrame.header.flags.rawValue & FrameFlags.keepAliveRespond.rawValue != 0, "Expected respond flag to be set")
        XCTAssertEqual(keepAliveFrame.lastReceivedPosition, 10)
    }

    /* Test for valid Keep Alive Frame.
     * The validation should pass if streamId is 0 and lastReceivedPosition >= 0;
     */
    func testKeepAliveFramePassValidation() {
        let frameData = "test data".data(using: .utf8)!
        let keepAliveFrame = KeepAliveFrame(respondWithKeepalive: true, lastReceivedPosition: 10, data: frameData)

        XCTAssertNoThrow(try keepAliveFrame.validate())
    }

    /* Test for invalid Keep Alive Frame.
     * The validation should fail if lastReceivedPosition is negative.
     */
    func testKeepAliveFrameFailValidation() {
        let frameData = "test data".data(using: .utf8)!
        let keepAliveFrame = KeepAliveFrame(respondWithKeepalive: true, lastReceivedPosition: -1, data: frameData)

        XCTAssertThrowsError(try keepAliveFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "lastReceivedPosition has to be equal or bigger than 0")
        }
    }

    /* Test Keep Alive Frame Encoder.
     * Encode a keep alive frame and ensure bytes returned are as expected.
     */
    func testKeepAliveEncoder() {
        let frameData = "d".data(using: .utf8)!
        let keepAliveFrame = KeepAliveFrame(respondWithKeepalive: true, lastReceivedPosition: 10, data: frameData)

        guard var byteBuffer = try? KeepAliveFrameEncoder().encode(frame: keepAliveFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 15)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), KeepAliveFrameTests.bytes)
    }

    /* Test for Keep Alive Frame Decoder.
     * Verify that the decoded byte buffer is keep alive frame.
     */
    func testKeepAliveDecoder() {
        var byteBuffer = ByteBuffer(bytes: KeepAliveFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedKeepAliveFrame = try? KeepAliveFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedKeepAliveFrame.header.type, .keepalive, "Expected keep alive frame type")
        XCTAssert(decodedKeepAliveFrame.header.flags.rawValue & FrameFlags.keepAliveRespond.rawValue != 0, "Expected respond flag to be set")
        XCTAssertEqual(decodedKeepAliveFrame.lastReceivedPosition, 10)
        XCTAssertEqual(decodedKeepAliveFrame.data, "d".data(using: .utf8)!)
    }

    /* Test for Keep Alive Frame Coding.
     * This test encodes keep alive frame and gets the byte buffer.
     * Then decodes the byte buffer using keep alive frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testKeepAliveFrameCoder() {
        let frameData = "test data".data(using: .utf8)!
        let keepAliveFrame = KeepAliveFrame(respondWithKeepalive: false, lastReceivedPosition: 10, data: frameData)

        guard var byteBuffer = try? KeepAliveFrameEncoder().encode(frame: keepAliveFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedKeepAliveFrame = try? KeepAliveFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertNotNil(decodedKeepAliveFrame)
        XCTAssertEqual(decodedKeepAliveFrame.header.type, .keepalive, "Expected keep alive frame type")
        XCTAssert(decodedKeepAliveFrame.header.flags.rawValue & FrameFlags.keepAliveRespond.rawValue == 0, "Expected respond flag to not be set")
        XCTAssertEqual(decodedKeepAliveFrame.lastReceivedPosition, 10)
        XCTAssertEqual(decodedKeepAliveFrame.data, frameData)
    }

    /* Test for Keep Alive Frame respond flag.
     * The respond flag should be set if respondWithKeepalive is true.
     */
    func testKeepAliveFrameRespondFlagSet() {
        let frameData = "d".data(using: .utf8)!
        let keepAliveFrame = KeepAliveFrame(respondWithKeepalive: true, lastReceivedPosition: 10, data: frameData)

        guard var byteBuffer = try? KeepAliveFrameEncoder().encode(frame: keepAliveFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        XCTAssertEqual(decodedFrameHeader.type, .keepalive, "Expected keep alive frame type")
        XCTAssert(decodedFrameHeader.flags.rawValue & FrameFlags.keepAliveRespond.rawValue != 0, "Expected respond flag to be set")
    }

    /* Test for Keep Alive Frame respond flag not set.
     * The respond flag should not be set if respondWithKeepalive is false.
     */
    func testKeepAliveFrameRespondFlagNotSet() {
        let frameData = "d".data(using: .utf8)!
        let keepAliveFrame = KeepAliveFrame(respondWithKeepalive: false, lastReceivedPosition: 10, data: frameData)

        guard var byteBuffer = try? KeepAliveFrameEncoder().encode(frame: keepAliveFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        XCTAssertEqual(decodedFrameHeader.type, .keepalive, "Expected keep alive frame type")
        XCTAssert(decodedFrameHeader.flags.rawValue & FrameFlags.keepAliveRespond.rawValue == 0, "Expected respond flag to not be set")
    }
}

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

final class ExtensionFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         63, 0, 0, 0,
                                         0, 7, 0, 0,
                                         1, 109, 100]

    /* Test Extension Frame initialisation with streamId, canBeIgnored, extendedType and payload.
     * Verify that the frame is initialised with expected values.
     */
    func testExtensionInit() {
        let payloadMetadata = "test metadata".data(using: .utf8)!
        let payloadData = "test data".data(using: .utf8)!
        let extensionFrame = ExtensionFrame(streamId: 0, canBeIgnored: true, extendedType: 6, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(extensionFrame.header.type, .ext, "Expected extension frame type")
        XCTAssertEqual(extensionFrame.header.streamId, 0, "Expected steam id 0 in extension frame type")
        XCTAssert(extensionFrame.header.flags.rawValue & FrameFlags.ignore.rawValue != 0, "Expected ignore flag to be set")
        XCTAssert(extensionFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(extensionFrame.payload.metadata, payloadMetadata)
        XCTAssertEqual(extensionFrame.payload.data, payloadData)
        XCTAssertEqual(extensionFrame.extendedType, 6)
    }

    /* Test for valid Extension Frame. */
    func testExtensionFramePassValidation() {
        let payloadMetadata = "test metadata".data(using: .utf8)!
        let payloadData = "test data".data(using: .utf8)!
        let extensionFrame = ExtensionFrame(streamId: 0, canBeIgnored: true, extendedType: 6, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertNoThrow(try extensionFrame.validate())
    }

    /* Test for invalid Extension Frame. */
    func testExtensionFrameFailValidation() {
        let payloadMetadata = "test metadata".data(using: .utf8)!
        let payloadData = "test data".data(using: .utf8)!
        let extensionFrame = ExtensionFrame(streamId: 0, canBeIgnored: true, extendedType: -1, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertThrowsError(try extensionFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "extendedType has to be equal or bigger than 0")
        }
    }

    /* Test Extension Frame Encoder.
     * Encode an extension frame and verify that the bytes returned are as expected.
     */
    func testExtensionEncoder() {
        let payloadMetadata = "m".data(using: .utf8)!
        let payloadData = "d".data(using: .utf8)!
        let extensionFrame = ExtensionFrame(streamId: 0, canBeIgnored: true, extendedType: 7, payload: Payload(metadata: payloadMetadata, data: payloadData))

        guard var byteBuffer = try? ExtensionFrameEncoder().encode(frame: extensionFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 15)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), ExtensionFrameTests.bytes)
    }

    /* Test for Extension Frame Decoder.
     * Verify that the decoded byte buffer is an extension frame.
     */
    func testExtensionDecoder() {
        var byteBuffer = ByteBuffer(bytes: ExtensionFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedExtensionFrame = try? ExtensionFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer)else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedExtensionFrame.header.type, .ext, "Expected extension frame type")
        XCTAssertEqual(decodedExtensionFrame.header.streamId, 0, "Expected steam id 0 in extension frame type")
        XCTAssert(decodedExtensionFrame.header.flags.rawValue & FrameFlags.ignore.rawValue != 0, "Expected ignore flag to be set")
        XCTAssert(decodedExtensionFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedExtensionFrame.payload.metadata, "m".data(using: .utf8)!)
        XCTAssertEqual(decodedExtensionFrame.payload.data, "d".data(using: .utf8)!)
        XCTAssertEqual(decodedExtensionFrame.extendedType, 7)
    }

    /* Test for Extension Frame Coding.
     * This test encodes extension frame and gets the byte buffer.
     * Then decodes the byte buffer using extension frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testExtensionFrameCoder() {
        let payloadMetadata = "test metadata".data(using: .utf8)!
        let payloadData = "test data".data(using: .utf8)!
        let extensionFrame = ExtensionFrame(streamId: 0, canBeIgnored: true, extendedType: 6, payload: Payload(metadata: payloadMetadata, data: payloadData))

        guard var byteBuffer = try? ExtensionFrameEncoder().encode(frame: extensionFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedExtensionFrame = try? ExtensionFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer)else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedExtensionFrame.header.type, .ext, "Expected extension frame type")
        XCTAssertEqual(decodedExtensionFrame.header.streamId, 0, "Expected steam id 0 in extension frame type")
        XCTAssert(decodedExtensionFrame.header.flags.rawValue & FrameFlags.ignore.rawValue != 0, "Expected ignore flag to be set")
        XCTAssert(decodedExtensionFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedExtensionFrame.payload.metadata, payloadMetadata)
        XCTAssertEqual(decodedExtensionFrame.payload.data, payloadData)
        XCTAssertEqual(decodedExtensionFrame.extendedType, 6)
    }
}

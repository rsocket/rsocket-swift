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

final class MetadataPushFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         49, 0, 109]

    /* Test Metadata Push Frame initialisation with metadata.
     * Verify that the frame is initialised with expected header and metadata.
     */
    func testMetadataPushInit() {
        let metadata = "test metadata".data(using: .utf8)!
        let metadataPushFrame = MetadataPushFrame(metadata: metadata)

        XCTAssertEqual(metadataPushFrame.header.type, .metadataPush, "Expected metadata push frame type")
        XCTAssertEqual(metadataPushFrame.header.streamId, 0, "Expected steam id 0 in metadata push frame type")
        XCTAssert(metadataPushFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(metadataPushFrame.metadata, metadata)
    }

    func testMetadataPushFrameValidation() {
        let metadata = "test metadata".data(using: .utf8)!
        let metadataPushFrame = MetadataPushFrame(metadata: metadata)

        XCTAssertNoThrow(try metadataPushFrame.validate())
    }

    /* Test Metadata Push Frame Encoder.
     * Encode a metadata push frame with metadata and check the bytes in encoded byte buffer.
     */
    func testMetadataPushEncoder() {
        let metadata = "m".data(using: .utf8)!
        let metadataPushFrame = MetadataPushFrame(metadata: metadata)

        guard var byteBuffer = try? MetadataPushFrameEncoder().encode(frame: metadataPushFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 7)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), MetadataPushFrameTests.bytes)
    }

    /* Test for Metadata Push Frame Decoder.
     * Verify that the decoded byte buffer is metadata push frame.
     */
    func testMetadataPushDecoder() {
        var byteBuffer = ByteBuffer(bytes: MetadataPushFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedMetadataPushFrame = try? MetadataPushFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedMetadataPushFrame.header.type, .metadataPush, "Expected metadata push frame type")
        XCTAssertEqual(decodedMetadataPushFrame.header.streamId, 0, "Expected steam id 0 in metadata push frame type")
        XCTAssert(decodedMetadataPushFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedMetadataPushFrame.metadata, "m".data(using: .utf8)!)
    }

    /* Test for Metadata Push Frame Coding.
     * This test encodes metadata push frame and gets the byte buffer.
     * Then decodes the byte buffer using metadata push frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testMetadataPushFrameCoder() {
        let metadata = "test metadata".data(using: .utf8)!
        let metadataPushFrame = MetadataPushFrame(metadata: metadata)

        guard var byteBuffer = try? MetadataPushFrameEncoder().encode(frame: metadataPushFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedMetadataPushFrame = try? MetadataPushFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedMetadataPushFrame.header.type, .metadataPush, "Expected metadata push frame type")
        XCTAssertEqual(decodedMetadataPushFrame.header.streamId, 0, "Expected steam id 0 in metadata push frame type")
        XCTAssert(decodedMetadataPushFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedMetadataPushFrame.metadata, metadata)
    }
}

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

final class FrameHeaderTests: XCTestCase {

    func testFrameHeaderType() {
        let frameHeader = FrameHeader(streamId: 0, type: .cancel, flags: [])
        XCTAssertEqual(frameHeader.type, .cancel)
    }

    func testFrameHeaderStreamId() {
        let frameHeader = FrameHeader(streamId: 2, type: .setup, flags: [])
        XCTAssertEqual(frameHeader.streamId, 2)
    }

    func testFrameHeaderFlags() {
        let flags: FrameFlags = FrameFlags(rawValue: 24)
        let frameHeader = FrameHeader(streamId: 2, type: .payload, flags: flags)
        XCTAssertEqual(frameHeader.flags, flags)
    }

    func testFrameHeaderPassValidation() {
        let frameHeader = FrameHeader(streamId: 2, type: .setup, flags: [])

        XCTAssertNoThrow(try frameHeader.validate())
    }

    func testFrameHeaderFailValidation() {
        let frameHeader = FrameHeader(streamId: -1, type: .setup, flags: [])

        XCTAssertThrowsError(try frameHeader.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "streamId has to be equal or bigger than 0")
        }
    }

    func testFrameHeaderEncoder() {
        let frameHeader = FrameHeader(streamId: 2, type: .cancel, flags: [])

        guard var byteBuffer = try? FrameHeaderEncoder().encode(header: frameHeader, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 6)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), [0, 0, 0, 2,
                                                                                  36, 0])
    }

    func testFrameHeaderDecoder() {
        var byteBuffer = ByteBuffer(bytes: [0x00, 0x00,
                                                        0x00, 0x02,
                                                        0x05, 0x00])
        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        XCTAssertEqual(decodedFrameHeader.streamId, 2)
        XCTAssertEqual(decodedFrameHeader.type, .setup)
        XCTAssert(decodedFrameHeader.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
    }

    func testTypeAndFlags() {
        let flags: FrameFlags = FrameFlags(rawValue: 0b1110110111) // 10 bits
        let frameHeader = FrameHeader(streamId: 0, type: .requestFnf, flags: flags)

        guard var byteBuffer = try? FrameHeaderEncoder().encode(header: frameHeader, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        XCTAssertEqual(decodedFrameHeader.flags, flags)
    }

    func testFlagsTruncated() {
        let flags: FrameFlags = FrameFlags(rawValue: 0b11111111111) // 11 bits
        let frameHeader = FrameHeader(streamId: 0, type: .requestFnf, flags: flags)

        guard var byteBuffer = try? FrameHeaderEncoder().encode(header: frameHeader, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        XCTAssertNotEqual(decodedFrameHeader.flags, flags)
        XCTAssertEqual(decodedFrameHeader.flags, FrameFlags(rawValue: 0b1111111111))
    }

    func testMetadataFlag() {
        let flags: FrameFlags = FrameFlags(rawValue: 0b0100000000)
        let frameHeader = FrameHeader(streamId: 0, type: .requestFnf, flags: flags)

        guard var byteBuffer = try? FrameHeaderEncoder().encode(header: frameHeader, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        XCTAssert(decodedFrameHeader.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
    }

    func testIgnoreFlag() {
        let flags: FrameFlags = FrameFlags(rawValue: 0b1000000000)
        let frameHeader = FrameHeader(streamId: 0, type: .ext, flags: flags)

        guard var byteBuffer = try? FrameHeaderEncoder().encode(header: frameHeader, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        XCTAssert(decodedFrameHeader.flags.rawValue & FrameFlags.ignore.rawValue != 0, "Expected ignore flag to be set")
    }
}

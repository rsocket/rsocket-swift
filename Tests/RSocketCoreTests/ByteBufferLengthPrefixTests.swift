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

final class ByteBufferLengthPrefixTests: XCTestCase {
    private var buffer = ByteBuffer()
    func testMessageLengthOfZero() throws {
        let bytesWritten = try buffer.writeLengthPrefix(endianness: .big, as: UInt8.self) { buffer in
            // write nothing
        }
        XCTAssertEqual(bytesWritten, 1)
        XCTAssertEqual(buffer.readInteger(as: UInt8.self), 0)
        XCTAssertTrue(buffer.readableBytesView.isEmpty)
    }
    func testMessageLengthOfOne() throws {
        let bytesWritten = try buffer.writeLengthPrefix(endianness: .big, as: UInt8.self) { buffer in
            buffer.writeString("A")
        }
        XCTAssertEqual(bytesWritten, 2)
        XCTAssertEqual(buffer.readInteger(as: UInt8.self), 1)
        XCTAssertEqual(buffer.readString(length: 1), "A")
        XCTAssertTrue(buffer.readableBytesView.isEmpty)
    }
    func testMessageWithMultipleWrites() throws {
        let bytesWritten = try buffer.writeLengthPrefix(endianness: .big, as: UInt8.self) { buffer in
            buffer.writeString("Hello")
            buffer.writeString(" ")
            buffer.writeString("World")
        }
        XCTAssertEqual(bytesWritten, 12)
        XCTAssertEqual(buffer.readInteger(as: UInt8.self), 11)
        XCTAssertEqual(buffer.readString(length: 11), "Hello World")
        XCTAssertTrue(buffer.readableBytesView.isEmpty)
    }
    func testMessageWithMaxLength() throws {
        let messageWithMaxLength = String(repeating: "A", count: 255)
        let bytesWritten = try buffer.writeLengthPrefix(endianness: .big, as: UInt8.self) { buffer in
            buffer.writeString(messageWithMaxLength)
        }
        XCTAssertEqual(bytesWritten, 256)
        XCTAssertEqual(buffer.readInteger(as: UInt8.self), 255)
        XCTAssertEqual(buffer.readString(length: 255), messageWithMaxLength)
        XCTAssertTrue(buffer.readableBytesView.isEmpty)
    }
    func testTooLongMessage() throws {
        let messageWithMaxLength = String(repeating: "A", count: 256)
        XCTAssertThrowsError(
            try buffer.writeLengthPrefix(endianness: .big, as: UInt8.self) { buffer in
                buffer.writeString(messageWithMaxLength)
            }
        )
    }
}

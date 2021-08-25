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

import NIOCore
@testable import RSocketCore
import XCTest

final class ByteBufferUInt24Tests: XCTestCase {
    func testSetUInt24WithUInt8BigEndian() {
        let firstByte: UInt8 = 0b00000000
        let secondByte: UInt8 = 0b00000000
        let thirdByte: UInt8 = 0b00001111
        let combinedInteger: UInt8 = 0b00001111
        var expectedBuffer = ByteBuffer()
        expectedBuffer.setBytes([firstByte, secondByte, thirdByte], at: 0)
        var actualBuffer = ByteBuffer()
        actualBuffer.setUInt24(combinedInteger, at: 0, endianness: .big)
        XCTAssertEqual(actualBuffer, expectedBuffer)
    }

    func testSetUInt24WithUInt16BigEndian() {
        let firstByte: UInt8 = 0b00000000
        let secondByte: UInt8 = 0b11000011
        let thirdByte: UInt8 = 0b00001111
        let combinedInteger: UInt16 = 0b11000011_00001111
        var expectedBuffer = ByteBuffer()
        expectedBuffer.setBytes([firstByte, secondByte, thirdByte], at: 0)
        var actualBuffer = ByteBuffer()
        actualBuffer.setUInt24(combinedInteger, at: 0, endianness: .big)
        XCTAssertEqual(actualBuffer, expectedBuffer)
    }

    func testSetUInt24WithUInt32BigEndian() {
        let firstByte: UInt8 = 0b00111100
        let secondByte: UInt8 = 0b11000011
        let thirdByte: UInt8 = 0b00001111
        let combinedInteger: UInt32 = 0b00000000_00111100_11000011_00001111
        var expectedBuffer = ByteBuffer()
        expectedBuffer.setBytes([firstByte, secondByte, thirdByte], at: 0)
        var actualBuffer = ByteBuffer()
        actualBuffer.setUInt24(combinedInteger, at: 0, endianness: .big)
        XCTAssertEqual(actualBuffer, expectedBuffer)
    }

    func testSetUInt24WithUInt8LittleEndian() {
        let firstByte: UInt8 = 0b00000000
        let secondByte: UInt8 = 0b00000000
        let thirdByte: UInt8 = 0b00001111
        let combinedInteger: UInt8 = 0b00001111
        var expectedBuffer = ByteBuffer()
        expectedBuffer.setBytes([thirdByte, secondByte, firstByte], at: 0)
        var actualBuffer = ByteBuffer()
        actualBuffer.setUInt24(combinedInteger, at: 0, endianness: .little)
        XCTAssertEqual(actualBuffer, expectedBuffer)
    }

    func testSetUInt24WithUInt16LittleEndian() {
        let firstByte: UInt8 = 0b00000000
        let secondByte: UInt8 = 0b11000011
        let thirdByte: UInt8 = 0b00001111
        let combinedInteger: UInt16 = 0b11000011_00001111
        var expectedBuffer = ByteBuffer()
        expectedBuffer.setBytes([thirdByte, secondByte, firstByte], at: 0)
        var actualBuffer = ByteBuffer()
        actualBuffer.setUInt24(combinedInteger, at: 0, endianness: .little)
        XCTAssertEqual(actualBuffer, expectedBuffer)
    }

    func testSetUInt24WithUInt32LittleEndian() {
        let firstByte: UInt8 = 0b00111100
        let secondByte: UInt8 = 0b11000011
        let thirdByte: UInt8 = 0b00001111
        let combinedInteger: UInt32 = 0b00000000_00111100_11000011_00001111
        var expectedBuffer = ByteBuffer()
        expectedBuffer.setBytes([thirdByte, secondByte, firstByte], at: 0)
        var actualBuffer = ByteBuffer()
        actualBuffer.setUInt24(combinedInteger, at: 0, endianness: .little)
        XCTAssertEqual(actualBuffer, expectedBuffer)
    }

    func testWriteUInt24IncrementsWriterIndexByThree() {
        let integer: UInt32 = 0
        var buffer = ByteBuffer()
        buffer.writeUInt24(integer)
        XCTAssertEqual(buffer.writerIndex, 3)
    }

    func testGetUInt24BigEndian() {
        let firstByte: UInt8 = 0b00111100
        let secondByte: UInt8 = 0b11000011
        let thirdByte: UInt8 = 0b00001111
        let expectedInteger: UInt32 = 0b00000000_00111100_11000011_00001111
        let buffer = ByteBuffer(bytes: [firstByte, secondByte, thirdByte])
        let actualInteger = buffer.getUInt24(at: 0, endianness: .big)
        XCTAssertEqual(actualInteger, expectedInteger)
    }

    func testGetUInt24LittleEndian() {
        let firstByte: UInt8 = 0b00111100
        let secondByte: UInt8 = 0b11000011
        let thirdByte: UInt8 = 0b00001111
        let expectedInteger: UInt32 = 0b00000000_00111100_11000011_00001111
        let buffer = ByteBuffer(bytes: [thirdByte, secondByte, firstByte])
        let actualInteger = buffer.getUInt24(at: 0, endianness: .little)
        XCTAssertEqual(actualInteger, expectedInteger)
    }

    func testReadUInt24IncrementsReaderIndexByThree() {
        let firstByte: UInt8 = 0b00111100
        let secondByte: UInt8 = 0b11000011
        let thirdByte: UInt8 = 0b00001111
        var buffer = ByteBuffer(bytes: [firstByte, secondByte, thirdByte])
        buffer.readUInt24()
        XCTAssertEqual(buffer.readerIndex, 3)
    }
}

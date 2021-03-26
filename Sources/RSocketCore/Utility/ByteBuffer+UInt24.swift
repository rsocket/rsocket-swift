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

extension ByteBuffer {
    @discardableResult
    @inlinable
    internal mutating func setUInt24<T: FixedWidthInteger & UnsignedInteger>(
        _ integer: T,
        at index: Int,
        endianness: Endianness = .big,
        as: T.Type = T.self
    ) -> Int {
        let mostSignificant: UInt16
        let leastSignificant: UInt8
        if T.bitWidth <= UInt8.bitWidth {
            mostSignificant = 0
            leastSignificant = UInt8(integer)
        } else {
            mostSignificant = UInt16(truncatingIfNeeded: integer >> UInt8.bitWidth)
            leastSignificant = UInt8(truncatingIfNeeded: integer)
        }
        switch endianness {
        case .big:
            setInteger(mostSignificant, at: index, endianness: .big)
            setInteger(leastSignificant, at: index + 2, endianness: .big)
        case .little:
            setInteger(leastSignificant, at: index, endianness: .little)
            setInteger(mostSignificant, at: index + 1, endianness: .little)
        }
        return 3
    }

    @discardableResult
    @inlinable
    internal mutating func writeUInt24<T: FixedWidthInteger & UnsignedInteger>(
        _ integer: T,
        endianness: Endianness = .big,
        as: T.Type = T.self
    ) -> Int {
        let bytesWritten = setUInt24(integer, at: writerIndex, endianness: endianness)
        moveWriterIndex(forwardBy: bytesWritten)
        return bytesWritten
    }

    @inlinable
    internal func getUInt24(
        at index: Int,
        endianness: Endianness = .big
    ) -> UInt32? {
        let mostSignificant: UInt16
        let leastSignificant: UInt8
        switch endianness {
        case .big:
            guard let uint16 = getInteger(at: index, endianness: .big, as: UInt16.self),
                  let uint8 = getInteger(at: index + 2, endianness: .big, as: UInt8.self) else { return nil }
            mostSignificant = uint16
            leastSignificant = uint8
        case .little:
            guard let uint8 = getInteger(at: index, endianness: .little, as: UInt8.self),
                  let uint16 = getInteger(at: index + 1, endianness: .little, as: UInt16.self) else { return nil }
            mostSignificant = uint16
            leastSignificant = uint8
        }
        return (UInt32(mostSignificant) << 8) &+ UInt32(leastSignificant)
    }

    @discardableResult
    @inlinable
    internal mutating func readUInt24(
        endianness: Endianness = .big
    ) -> UInt32? {
        guard let integer = getUInt24(at: readerIndex, endianness: endianness) else { return nil }
        moveReaderIndex(forwardBy: 3)
        return integer
    }
}

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

@usableFromInline
internal enum RSocketLengthPrefixError: Swift.Error {
    case messageLengthDoesNotFitExactlyIntoRequiredIntegerFormat
}

extension ByteBuffer {
    /// Prefixes a message written by `writeMessage` with the number of bytes written as an `Integer`.
    /// - Throws: If the number of bytes written during `writeMessage` can not be exactly represented as the given `Integer` i.e. if the number of bytes written is greater than `Integer.max`
    /// - Returns: Number of total bytes written
    @discardableResult
    @inlinable
    internal mutating func writeLengthPrefix<Integer: FixedWidthInteger>(
        endianness: Endianness = .big,
        as integer: Integer.Type = Integer.self,
        writeMessage: (inout ByteBuffer) throws -> ()
    ) throws -> Int {
        let lengthPrefixIndex = writerIndex
        // Write a zero as a placeholder which will later be overwritten by the actual number of bytes written
        var totalBytesWritten = writeInteger(.zero, endianness: endianness, as: Integer.self)
        
        let messageStartIndex = writerIndex
        try writeMessage(&self)
        let messageEndIndex = writerIndex
        
        let messageLength = messageEndIndex - messageStartIndex
        totalBytesWritten += messageLength
        
        guard let lengthPrefix = Integer(exactly: messageLength) else {
            throw RSocketLengthPrefixError.messageLengthDoesNotFitExactlyIntoRequiredIntegerFormat
        }
        setInteger(lengthPrefix, at: lengthPrefixIndex, endianness: endianness, as: Integer.self)
        
        return totalBytesWritten
    }
}

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

public struct FrameHeaderDecoder {
    public func decode(buffer: inout ByteBuffer) throws -> FrameHeader {
        guard let streamId: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let typeAndFlagBytes: UInt16 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        // leading 6 bits are the type
        let typeValue = UInt8(truncatingIfNeeded: typeAndFlagBytes >> 10)
        guard let type = FrameType(rawValue: typeValue) else {
            throw FrameError.header(.unknownType(typeValue))
        }
        // trailing 10 bits are the flags
        let flagValue = typeAndFlagBytes & 0b0000001111111111
        let flags = FrameFlags(rawValue: flagValue)
        return FrameHeader(streamId: streamId, type: type, flags: flags)
    }
}

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

internal protocol FrameHeaderEncoding {
    func encode(header: FrameHeader, into buffer: inout ByteBuffer) throws
}

internal struct FrameHeaderEncoder: FrameHeaderEncoding {
    internal func encode(header: FrameHeader, into buffer: inout ByteBuffer) throws {
        buffer.writeInteger(header.streamId.rawValue)
        // shift type by amount of flag bits
        let typeBits = UInt16(header.type.rawValue) << 10
        // only use trailing 10 bits for flags
        let flagBits = header.flags.rawValue & 0b0000001111111111
        buffer.writeInteger(typeBits | flagBits)
    }
}

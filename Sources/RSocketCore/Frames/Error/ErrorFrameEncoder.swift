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

internal struct ErrorFrameEncoder: FrameEncoding {
    private let headerEncoder: FrameHeaderEncoding

    internal init(headerEncoder: FrameHeaderEncoding = FrameHeaderEncoder()) {
        self.headerEncoder = headerEncoder
    }

    internal func encode(frame: ErrorFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try headerEncoder.encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.error.code)
        if !frame.error.message.isEmpty {
            let bytesWritten = buffer.writeString(frame.error.message)
            guard bytesWritten > 0 else {
                throw Error.connectionError(message: "Error message contains invalid characters")
            }
        }
        return buffer
    }
}

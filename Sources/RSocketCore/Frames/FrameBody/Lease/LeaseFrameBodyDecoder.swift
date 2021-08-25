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

import Foundation
import NIOCore

internal struct LeaseFrameBodyDecoder: FrameBodyDecoding {
    internal func decode(from buffer: inout ByteBuffer, header: FrameHeader) throws -> LeaseFrameBody {
        guard let timeToLive: Int32 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let numberOfRequests: Int32 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        let metadata: ByteBuffer?
        if header.flags.contains(.metadata) {
            metadata = buffer.readSlice(length: buffer.readableBytes) ?? ByteBuffer()
        } else {
            metadata = nil
        }
        return LeaseFrameBody(
            timeToLive: timeToLive,
            numberOfRequests: numberOfRequests,
            metadata: metadata
        )
    }
}

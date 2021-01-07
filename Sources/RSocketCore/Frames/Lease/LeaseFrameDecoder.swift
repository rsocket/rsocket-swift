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
import NIO

internal struct LeaseFrameDecoder: FrameDecoding {
    internal func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> LeaseFrame {
        guard let timeToLive: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let numberOfRequests: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let metadata: Data?
        if header.flags.contains(.metadata) {
            if buffer.readableBytes > 0 {
                metadata = buffer.readData(length: buffer.readableBytes) ?? Data()
            } else {
                metadata = Data()
            }
        } else {
            metadata = nil
        }
        return LeaseFrame(
            header: header,
            timeToLive: timeToLive,
            numberOfRequests: numberOfRequests,
            metadata: metadata
        )
    }
}

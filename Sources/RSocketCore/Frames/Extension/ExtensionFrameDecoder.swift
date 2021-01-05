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

public struct ExtensionFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> ExtensionFrame {
        guard let extendedType: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let metadata: Data?
        if header.flags.contains(.metadata) {
            guard let metadataLengthBytes = buffer.readBytes(length: FrameConstants.metadataLengthFieldLengthInBytes) else {
                throw FrameError.tooSmall
            }
            let metadataLength = Int(bytes: metadataLengthBytes)
            guard let metadataData = buffer.readData(length: metadataLength) else {
                throw FrameError.tooSmall
            }
            metadata = metadataData
        } else {
            metadata = nil
        }
        let payload: Data
        if buffer.readableBytes > 0 {
            payload = buffer.readData(length: buffer.readableBytes) ?? Data()
        } else {
            payload = Data()
        }
        return ExtensionFrame(
            header: header,
            extendedType: extendedType,
            metadata: metadata,
            payload: payload
        )
    }
}

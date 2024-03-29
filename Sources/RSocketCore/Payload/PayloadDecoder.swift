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

internal protocol PayloadDecoding {
    func decode(from buffer: inout ByteBuffer, hasMetadata: Bool) throws -> Payload
}

internal struct PayloadDecoder: PayloadDecoding {
    internal func decode(from buffer: inout ByteBuffer, hasMetadata: Bool) throws -> Payload {
        let metadata: ByteBuffer?
        if hasMetadata {
            guard let metadataLength = buffer.readUInt24() else {
                throw Error.connectionError(message: "Frame is not big enough")
            }
            guard let metadataData = buffer.readSlice(length: Int(metadataLength)) else {
                throw Error.connectionError(message: "Frame is not big enough")
            }
            metadata = metadataData
        } else {
            metadata = nil
        }
        let data = buffer.readSlice(length: buffer.readableBytes) ?? ByteBuffer()
        return Payload(metadata: metadata, data: data)
    }
}

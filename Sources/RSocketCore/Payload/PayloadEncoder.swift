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

internal protocol PayloadEncoding {
    func encode(payload: Payload, to buffer: inout ByteBuffer) throws
}

internal struct PayloadEncoder: PayloadEncoding {
    internal func encode(payload: Payload, to buffer: inout ByteBuffer) throws {
        if let metadata = payload.metadata {
            guard metadata.count <= FrameBodyConstants.metadataMaximumLength else {
                throw Error.connectionError(message: "Metadata is too big")
            }
            let metadataLengthBytes = UInt32(metadata.count).bytes.suffix(FrameBodyConstants.metadataLengthFieldLengthInBytes)
            buffer.writeBytes(metadataLengthBytes)
            buffer.writeData(metadata)
        }
        buffer.writeData(payload.data)
    }
}

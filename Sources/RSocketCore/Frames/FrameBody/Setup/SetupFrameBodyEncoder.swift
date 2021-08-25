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
import NIOFoundationCompat

internal struct SetupFrameBodyEncoder: FrameBodyEncoding {
    private let payloadEncoder: PayloadEncoding

    internal init(payloadEncoder: PayloadEncoding = PayloadEncoder()) {
        self.payloadEncoder = payloadEncoder
    }

    internal func encode(frame: SetupFrameBody, into buffer: inout ByteBuffer) throws {
        buffer.writeInteger(frame.version.major)
        buffer.writeInteger(frame.version.minor)
        buffer.writeInteger(frame.timeBetweenKeepaliveFrames)
        buffer.writeInteger(frame.maxLifetime)
        if let token = frame.resumeIdentificationToken {
            guard token.count <= UInt16.max else {
                throw Error.connectionError(message: "resumeIdentificationToken is too big")
            }
            buffer.writeInteger(UInt16(token.count))
            buffer.writeData(token)
        }
        guard let metadataEncodingMimeTypeAsciiData = frame.metadataEncodingMimeType.data(using: .ascii) else {
            throw Error.connectionError(message: "metadataEncodingMimeType contains invalid characters")
        }
        guard metadataEncodingMimeTypeAsciiData.count <= UInt8.max else {
            throw Error.connectionError(message: "Metadata is too big")
        }
        buffer.writeInteger(UInt8(metadataEncodingMimeTypeAsciiData.count))
        buffer.writeData(metadataEncodingMimeTypeAsciiData)
        guard let dataEncodingMimeTypeAsciiData = frame.dataEncodingMimeType.data(using: .ascii) else {
            throw Error.connectionError(message: "dataEncodingMimeType contains invalid characters")
        }
        guard dataEncodingMimeTypeAsciiData.count <= UInt8.max else {
            throw Error.connectionError(message: "Data is too big")
        }
        buffer.writeInteger(UInt8(dataEncodingMimeTypeAsciiData.count))
        buffer.writeData(dataEncodingMimeTypeAsciiData)
        try payloadEncoder.encode(payload: frame.payload, to: &buffer)
    }
}

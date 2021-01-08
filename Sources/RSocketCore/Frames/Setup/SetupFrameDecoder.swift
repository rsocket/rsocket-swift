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
import NIOFoundationCompat

internal struct SetupFrameDecoder: FrameDecoding {
    private let payloadDecoder: PayloadDecoding

    internal init(payloadDecoder: PayloadDecoding = PayloadDecoder()) {
        self.payloadDecoder = payloadDecoder
    }

    internal func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> SetupFrame {
        guard let majorVersion: UInt16 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let minorVersion: UInt16 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let timeBetweenKeepaliveFrames: Int32 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let maxLifetime: Int32 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        let resumeIdentificationToken: Data?
        if header.flags.contains(.setupResume) {
            guard let resumeTokenLength: UInt16 = buffer.readInteger() else {
                throw Error.connectionError(message: "Frame is not big enough")
            }
            guard let resumeTokenData = buffer.readData(length: Int(resumeTokenLength)) else {
                throw Error.connectionError(message: "Frame is not big enough")
            }
            resumeIdentificationToken = resumeTokenData
        } else {
            resumeIdentificationToken = nil
        }
        guard let metadataEncodingMimeTypeLength: UInt8 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard metadataEncodingMimeTypeLength <= buffer.readableBytes else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let metadataEncodingMimeType = buffer.readString(length: Int(metadataEncodingMimeTypeLength), encoding: .ascii) else {
            throw Error.connectionError(message: "metadataEncodingMimeType contains invalid characters")
        }
        guard let dataEncodingMimeTypeLength: UInt8 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard dataEncodingMimeTypeLength <= buffer.readableBytes else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let dataEncodingMimeType = buffer.readString(length: Int(dataEncodingMimeTypeLength), encoding: .ascii) else {
            throw Error.connectionError(message: "dataEncodingMimeType contains invalid characters")
        }
        let payload = try payloadDecoder.decode(from: &buffer, hasMetadata: header.flags.contains(.metadata))
        return SetupFrame(
            header: header,
            majorVersion: majorVersion,
            minorVersion: minorVersion,
            timeBetweenKeepaliveFrames: timeBetweenKeepaliveFrames,
            maxLifetime: maxLifetime,
            resumeIdentificationToken: resumeIdentificationToken,
            metadataEncodingMimeType: metadataEncodingMimeType,
            dataEncodingMimeType: dataEncodingMimeType,
            payload: payload
        )
    }
}

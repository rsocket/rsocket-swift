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

public struct MIMETypeEncoder {
    public static let defaultWellKnownMimeTypes = Dictionary(
        uniqueKeysWithValues: MIMEType.wellKnownMIMETypes.lazy.map{ ($0.1, $0.0) }
    )
    
    @usableFromInline
    internal let wellKnownMimeTypes: [MIMEType: WellKnownMIMETypeCode]
    
    @inlinable
    public init(
        wellKnownMimeTypes: [MIMEType : WellKnownMIMETypeCode] = defaultWellKnownMimeTypes
    ) {
        self.wellKnownMimeTypes = wellKnownMimeTypes
    }
    
    @inlinable
    public func encode(_ mimeType: MIMEType, into buffer: inout ByteBuffer) throws {
        if let wellKnownMimeType = wellKnownMimeTypes[mimeType] {
            encodeWellKnown(wellKnownMimeType, into: &buffer)
        } else {
            try encodeUnknown(mimeType, into: &buffer)
        }
    }
    
    @inlinable
    internal func encodeWellKnown(_ mimeType: WellKnownMIMETypeCode, into buffer: inout ByteBuffer) {
        buffer.writeInteger(mimeType.withFlagBitSet)
    }
    
    @inlinable
    internal func encodeUnknown(_ mimeType: MIMEType, into buffer: inout ByteBuffer) throws {
        do {
            try buffer.writeLengthPrefixed(as: Int8.self) { buffer in
                buffer.writeString(mimeType.rawValue)
            } 
        } catch {
            throw Error.invalid(message: "MIME Type \(mimeType) too long to encode")
        }
    }
}



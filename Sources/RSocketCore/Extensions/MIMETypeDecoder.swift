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

public struct MIMETypeDecoder {
    public static let defaultWellKnownMimeTypes = Dictionary(uniqueKeysWithValues: MIMEType.wellKnownMIMETypes)
    
    @usableFromInline
    internal var wellKnownMimeTypes: [WellKnownMIMETypeCode: MIMEType]
    
    @inlinable
    public init(
        wellKnownMimeTypes: [WellKnownMIMETypeCode : MIMEType] = defaultWellKnownMimeTypes
    ) {
        self.wellKnownMimeTypes = wellKnownMimeTypes
    }
    
    @inlinable
    public func decode(from buffer: inout ByteBuffer) throws -> MIMEType {
        guard let idOrLength = buffer.readInteger(as: Int8.self) else {
            throw Error.invalid(message: "could not read MIME Type id/length")
        }
        if idOrLength >= 0 {
            return try decodeUnknownOfLength(idOrLength, from: &buffer)
        } else {
            return try decodeWellKnownWithId(idOrLength, from: &buffer)
        }
    }
    
    @inlinable
    internal func decodeUnknownOfLength(_ length: Int8, from buffer: inout ByteBuffer) throws -> MIMEType {
        guard let mimeType = buffer.readString(length: Int(length)) else {
            throw Error.invalid(message: "could not read MIME Type string")
        }
        return MIMEType(rawValue: mimeType)
    }
    
    @inlinable
    internal func decodeWellKnownWithId(_ id: Int8, from buffer: inout ByteBuffer) throws -> MIMEType {
        let code = WellKnownMIMETypeCode(withFlagBitSet: id)
        guard let wellKnownMimeType = wellKnownMimeTypes[code] else {
            throw Error.invalid(message: "unknown MIME Type id \(code)")
        }
        return wellKnownMimeType
    }
}

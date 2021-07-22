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
        fatalError("not implemented")
    }
}

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
        fatalError("not implemented")
    }
}

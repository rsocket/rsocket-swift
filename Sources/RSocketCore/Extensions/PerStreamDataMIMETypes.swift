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
    let wellKnownMimeTypes: [MIMEType: WellKnownMIMETypeCode]
    public init(
        wellKnownMimeTypes: [MIMEType : WellKnownMIMETypeCode] = defaultWellKnownMimeTypes
    ) {
        self.wellKnownMimeTypes = wellKnownMimeTypes
    }
    func encode(_ mimeType: MIMEType, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

public struct MIMETypeDecoder {
    public static let defaultWellKnownMimeTypes = Dictionary(uniqueKeysWithValues: MIMEType.wellKnownMIMETypes)
    var wellKnownMimeTypes: [WellKnownMIMETypeCode: MIMEType]
    public init(
        wellKnownMimeTypes: [WellKnownMIMETypeCode : MIMEType] = defaultWellKnownMimeTypes
    ) {
        self.wellKnownMimeTypes = wellKnownMimeTypes
    }
    func decode(from buffer: inout ByteBuffer) throws -> MIMEType {
        fatalError("not implemented")
    }
}


// MARK: - Data MIME Type

public struct DataMIMETypeEncoder: MetadataEncoder {
    public typealias Metadata = MIMEType
    public var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    let mimeTypeEncoder: MIMETypeEncoder
    public init(mimeTypeEncoder: MIMETypeEncoder = MIMETypeEncoder()) {
        self.mimeTypeEncoder = mimeTypeEncoder
    }
    public func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

public extension MetadataEncoder where Self == DataMIMETypeEncoder {
    static var dataMIMEType: Self { .init() }
}

public struct DataMIMETypeDecoder: MetadataDecoder {
    public typealias Metadata = MIMEType
    public var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    let mimeTypeDecoder: MIMETypeEncoder
    public init(mimeTypeDecoder: MIMETypeEncoder = MIMETypeEncoder()) {
        self.mimeTypeDecoder = mimeTypeDecoder
    }
    public func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

public extension MetadataDecoder where Self == DataMIMETypeDecoder {
    static var dataMIMEType: Self { .init() }
}

// MARK: - Acceptable Data MIME Type

public struct AcceptableDataMIMETypeEncoder: MetadataEncoder {
    public typealias Metadata = [MIMEType]
    public var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    let mimeTypeEncoder: MIMETypeEncoder
    public init(
        mimeTypeEncoder: MIMETypeEncoder = MIMETypeEncoder()
    ) {
        self.mimeTypeEncoder = mimeTypeEncoder
    }
    public func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

public extension MetadataEncoder where Self == AcceptableDataMIMETypeEncoder {
    static var acceptableDataMIMEType: Self { .init() }
}

public struct AcceptableDataMIMETypeDecoder: MetadataDecoder {
    public typealias Metadata = [MIMEType]
    public var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    let mimeTypeDecoder: MIMETypeEncoder
    public init(mimeTypeDecoder: MIMETypeEncoder = MIMETypeEncoder()) {
        self.mimeTypeDecoder = mimeTypeDecoder
    }
    public func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

public extension MetadataDecoder where Self == AcceptableDataMIMETypeDecoder {
    static var acceptableDataMIMEType: Self { .init() }
}

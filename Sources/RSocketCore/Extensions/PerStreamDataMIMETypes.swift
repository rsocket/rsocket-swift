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

struct MIMETypeEncoder {
    private static let defaultWellKnownMimeTypes = Dictionary(
        uniqueKeysWithValues: MIMEType.wellKnownMIMETypes.lazy.map{ ($0.1, $0.0) }
    )
    var wellKnownMimeTypes: [MIMEType: WellKnownMIMETypeCode] = defaultWellKnownMimeTypes
    func encode(_ mimeType: MIMEType, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct MIMETypeDecoder {
    private static let defaultWellKnownMimeTypes = Dictionary(uniqueKeysWithValues: MIMEType.wellKnownMIMETypes)
    var wellKnownMimeTypes: [WellKnownMIMETypeCode: MIMEType] = defaultWellKnownMimeTypes
    func decode(from buffer: inout ByteBuffer) throws -> MIMEType {
        fatalError("not implemented")
    }
}


// MARK: - Data MIME Type

struct DataMIMETypeEncoder: MetadataEncoder {
    typealias Metadata = MIMEType
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct DataMIMETypeDecoder: MetadataDecoder {
    typealias Metadata = MIMEType
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeDecoder = MIMETypeEncoder()
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == DataMIMETypeEncoder {
    static var dataMIMEType: Self { .init() }
}

extension MetadataDecoder where Self == DataMIMETypeDecoder {
    static var dataMIMEType: Self { .init() }
}

// MARK: - Acceptable Data MIME Type

struct AcceptableDataMIMETypeEncoder: MetadataEncoder {
    typealias Metadata = [MIMEType]
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct AcceptableDataMIMETypeDecoder: MetadataDecoder {
    typealias Metadata = [MIMEType]
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeDecoder = MIMETypeEncoder()
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == AcceptableDataMIMETypeEncoder {
    static var acceptableDataMIMEType: Self { .init() }
}

extension MetadataDecoder where Self == AcceptableDataMIMETypeDecoder {
    static var acceptableDataMIMEType: Self { .init() }
}

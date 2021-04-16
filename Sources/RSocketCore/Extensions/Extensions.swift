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

struct CompositeMetadata {
    var mimeType: MIMEType
    var data: ByteBuffer
}

// - MARK: MIMEType

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

// - MARK: Metadata Coder

protocol MetadataEncoder {
    associatedtype Metadata
    var mimeType: MIMEType { get }
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws
}

protocol MetadataDecoder {
    associatedtype Metadata
    var mimeType: MIMEType { get }
    func decode(from buffer: inout ByteBuffer) throws -> Metadata
}

// - MARK: Composite Metadata

struct CompositeMetadataEncoder: MetadataEncoder {
    typealias Metadata = [CompositeMetadata]
    var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct CompositeMetadataDecoder: MetadataDecoder {
    typealias Metadata = [CompositeMetadata]
    var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    var mimeTypeDecoder = MIMETypeEncoder()
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

// - MARK: Routing

struct RoutingEncoder: MetadataEncoder {
    typealias Metadata = [String]
    var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct RoutingDecoder: MetadataDecoder {
    typealias Metadata = [String]
    var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

// - MARK: Composite Metadata

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

// - MARK: Composite Metadata

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

// - MARK:

enum MetadataError: Swift.Error {
    case decodingDidNotReadAllBytes
}

extension Sequence where Element == CompositeMetadata {
    func decodeFirst<Decoder>(
        using decoder: Decoder
    ) throws -> Decoder.Metadata? where Decoder: MetadataDecoder {
        guard var buffer = first(where: { $0.mimeType == decoder.mimeType })?.data else {
            return nil
        }
        let metadata = try decoder.decode(from: &buffer)
        guard buffer.readableBytes == 0 else {
            throw Error.invalid(message: "\(Decoder.self) did not read all bytes")
        }
        return metadata
    }
}

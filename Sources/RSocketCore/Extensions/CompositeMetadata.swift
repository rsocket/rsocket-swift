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
    var data: Data
}

struct CompositeMetadataEncoder: MetadataEncoder {
    typealias Metadata = [CompositeMetadata]
    var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

// Swift 5.5 does support static member lookup in a generic context: https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md
extension MetadataEncoder where Self == CompositeMetadataEncoder {
    static var compositeMetadata: Self { .init() }
}

extension MetadataDecoder where Self == CompositeMetadataDecoder {
    static var compositeMetadata: Self { .init() }
}

extension CompositeMetadata {
    static func encoded<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) throws -> Self where Encoder: MetadataEncoder {
        CompositeMetadata(
            mimeType: encoder.mimeType,
            data: try encoder.encode(metadata)
        )
    }
}

extension RangeReplaceableCollection where Element == CompositeMetadata {
    func encoded<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) throws -> Self where Encoder: MetadataEncoder {
        self + CollectionOfOne(try CompositeMetadata.encoded(metadata, using: encoder))
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

extension Sequence where Element == CompositeMetadata {
    func decodeFirst<Decoder>(
        using decoder: Decoder
    ) throws -> Decoder.Metadata? where Decoder: MetadataDecoder {
        guard let data = first(where: { $0.mimeType == decoder.mimeType })?.data else {
            return nil
        }
        return try decoder.decode(from: data)
    }
}

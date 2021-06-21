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

struct RootCompositeMetadataEncoder: MetadataEncoder {
    typealias Metadata = [CompositeMetadata]
    var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

// Swift 5.5 does support static member lookup in a generic context: https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md
extension MetadataEncoder where Self == RootCompositeMetadataEncoder {
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

struct RootCompositeMetadataDecoder: MetadataDecoder {
    typealias Metadata = [CompositeMetadata]
    var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    var mimeTypeDecoder = MIMETypeEncoder()
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataDecoder where Self == RootCompositeMetadataDecoder {
    static var compositeMetadata: Self { .init() }
}

enum CompositeMetadataDecodeError: Swift.Error {
    case requiredMetadataNotPresentForMIMEType(MIMEType)
}

extension Sequence where Element == CompositeMetadata {
    func decodeFirstIfPresent<Decoder>(
        using decoder: Decoder
    ) throws -> Decoder.Metadata? where Decoder: MetadataDecoder {
        guard let data = first(where: { $0.mimeType == decoder.mimeType })?.data else {
            return nil
        }
        return try decoder.decode(from: data)
    }
    func decodeFirst<Decoder>(
        using decoder: Decoder
    ) throws -> Decoder.Metadata where Decoder: MetadataDecoder {
        guard let metadata = try decodeFirstIfPresent(using: decoder) else {
            throw CompositeMetadataDecodeError.requiredMetadataNotPresentForMIMEType(decoder.mimeType)
        }
        return metadata
    }
}


// MARK: - Composite Metadata Payload Decoer

protocol CompositeMetadataDecoder {
    associatedtype Metadata
    func decode(from compositeMetadata: [CompositeMetadata]) throws -> Metadata
}


struct CompositeMetadataDecoderTuple2<A, B>: CompositeMetadataDecoder where
A: MetadataDecoder,
B: MetadataDecoder
{
    typealias Metadata = (A.Metadata, B.Metadata)
    let decoder: (A, B)
    func decode(from compositeMetadata: [CompositeMetadata]) throws -> Metadata {
        (
            try compositeMetadata.decodeFirst(using: decoder.0),
            try compositeMetadata.decodeFirst(using: decoder.1)
        )
    }
}

struct CompositeMetadataDecoderTuple3<A, B, C>: CompositeMetadataDecoder where
A: MetadataDecoder,
B: MetadataDecoder,
C: MetadataDecoder
{
    typealias Metadata = (A.Metadata, B.Metadata, C.Metadata)
    let decoder: (A, B, C)
    func decode(from compositeMetadata: [CompositeMetadata]) throws -> Metadata {
        (
            try compositeMetadata.decodeFirst(using: decoder.0),
            try compositeMetadata.decodeFirst(using: decoder.1),
            try compositeMetadata.decodeFirst(using: decoder.2)
        )
    }
}

@resultBuilder
enum CompositeMetadataDecoderBuilder {
    static func buildBlock<Decoder>(
        _ decoder: Decoder
    ) -> Decoder where Decoder: CompositeMetadataDecoder {
        decoder
    }
    static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> CompositeMetadataDecoderTuple2<A, B> {
        .init(decoder: (a, b))
    }
    static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> CompositeMetadataDecoderTuple3<A, B, C> {
        .init(decoder: (a, b, c))
    }
}

extension DecoderProtocol where Metadata == [CompositeMetadata] {
    func decodeMetadata<Decoder: CompositeMetadataDecoder>(
        @CompositeMetadataDecoderBuilder _ decoder: () -> Decoder
    ) -> Decoders.MapMetadata<Self, Decoder.Metadata> {
        let decoder = decoder()
        return mapMetadata(decoder.decode(from:))
    }
}

// MARK: - Composite Metadata Payload Encoder

protocol CompositeMetadataEncoder {
    associatedtype Metadata
    func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata]
}

struct CompositeMetadataEncoderTuple2<A, B>: CompositeMetadataEncoder where
A: MetadataEncoder,
B: MetadataEncoder
{
    typealias Metadata = (A.Metadata, B.Metadata)
    let encoder: (A, B)
    func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata] {
        [
            try CompositeMetadata.encoded(metadata.0, using: encoder.0),
            try CompositeMetadata.encoded(metadata.1, using: encoder.1),
        ]
    }
}

struct CompositeMetadataEncoderTuple3<A, B, C>: CompositeMetadataEncoder where
A: MetadataEncoder,
B: MetadataEncoder,
C: MetadataEncoder
{
    typealias Metadata = (A.Metadata, B.Metadata, C.Metadata)
    let encoder: (A, B, C)
    func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata] {
        [
            try CompositeMetadata.encoded(metadata.0, using: encoder.0),
            try CompositeMetadata.encoded(metadata.1, using: encoder.1),
            try CompositeMetadata.encoded(metadata.2, using: encoder.2),
        ]
    }
}


@resultBuilder
enum CompositeMetadataEncoderBuilder {
    static func buildBlock<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: CompositeMetadataEncoder {
        encoder
    }
    static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> CompositeMetadataEncoderTuple2<A, B> {
        .init(encoder: (a, b))
    }
    static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> CompositeMetadataEncoderTuple3<A, B, C> {
        .init(encoder: (a, b, c))
    }
}

extension EncoderProtocol where Metadata == [CompositeMetadata] {
    func encodeMetadata<Encoder: CompositeMetadataEncoder>(
        @CompositeMetadataEncoderBuilder _ encoder: () -> Encoder
    ) -> Encoders.MapMetadata<Self, Encoder.Metadata> {
        let encoder = encoder()
        return mapMetadata(encoder.encodeMetadata)
    }
}

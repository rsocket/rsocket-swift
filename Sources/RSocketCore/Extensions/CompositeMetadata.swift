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

public struct CompositeMetadata {
    public var mimeType: MIMEType
    public var data: Data
    public init(mimeType: MIMEType, data: Data) {
        self.mimeType = mimeType
        self.data = data
    }
}

// MARK: Root Composite Metadata Encoder

public struct RootCompositeMetadataEncoder: MetadataEncoder {
    public typealias Metadata = [CompositeMetadata]
    public var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    let mimeTypeEncoder: MIMETypeEncoder
    public init(mimeTypeEncoder: MIMETypeEncoder = MIMETypeEncoder()) {
        self.mimeTypeEncoder = mimeTypeEncoder
    }
    public func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

// Swift 5.5 does support static member lookup in a generic context: https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md
public extension MetadataEncoder where Self == RootCompositeMetadataEncoder {
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

// MARK: Root Composite Metadata Decoder

public struct RootCompositeMetadataDecoder: MetadataDecoder {
    public typealias Metadata = [CompositeMetadata]
    public var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    let mimeTypeDecoder: MIMETypeEncoder
    public init(mimeTypeDecoder: MIMETypeEncoder = MIMETypeEncoder()) {
        self.mimeTypeDecoder = mimeTypeDecoder
    }
    public func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataDecoder where Self == RootCompositeMetadataDecoder {
    static var compositeMetadata: Self { .init() }
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
            throw Error.invalid(message: "required Metadata not present for \(decoder.mimeType)")
        }
        return metadata
    }
}


// MARK: - Composite Metadata Payload Decoder

public protocol CompositeMetadataDecoder {
    associatedtype Metadata
    func decode(from compositeMetadata: [CompositeMetadata]) throws -> Metadata
}


public struct CompositeMetadataDecoderTuple2<A, B>: CompositeMetadataDecoder where
A: MetadataDecoder,
B: MetadataDecoder
{
    public typealias Metadata = (A.Metadata, B.Metadata)
    let decoder: (A, B)
    public func decode(from compositeMetadata: [CompositeMetadata]) throws -> Metadata {
        (
            try compositeMetadata.decodeFirst(using: decoder.0),
            try compositeMetadata.decodeFirst(using: decoder.1)
        )
    }
}

public struct CompositeMetadataDecoderTuple3<A, B, C>: CompositeMetadataDecoder where
A: MetadataDecoder,
B: MetadataDecoder,
C: MetadataDecoder
{
    public typealias Metadata = (A.Metadata, B.Metadata, C.Metadata)
    let decoder: (A, B, C)
    public func decode(from compositeMetadata: [CompositeMetadata]) throws -> Metadata {
        (
            try compositeMetadata.decodeFirst(using: decoder.0),
            try compositeMetadata.decodeFirst(using: decoder.1),
            try compositeMetadata.decodeFirst(using: decoder.2)
        )
    }
}

@resultBuilder
public enum CompositeMetadataDecoderBuilder {
    public static func buildBlock<Decoder>(
        _ decoder: Decoder
    ) -> Decoder where Decoder: CompositeMetadataDecoder {
        decoder
    }
    public static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> CompositeMetadataDecoderTuple2<A, B> {
        .init(decoder: (a, b))
    }
    public static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> CompositeMetadataDecoderTuple3<A, B, C> {
        .init(decoder: (a, b, c))
    }
}

// MARK: - Composite Metadata Payload Encoder

public protocol CompositeMetadataEncoder {
    associatedtype Metadata
    func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata]
}

public struct CompositeMetadataEncoderTuple2<A, B>: CompositeMetadataEncoder where
A: MetadataEncoder,
B: MetadataEncoder
{
    public typealias Metadata = (A.Metadata, B.Metadata)
    let encoder: (A, B)
    public func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata] {
        [
            try CompositeMetadata.encoded(metadata.0, using: encoder.0),
            try CompositeMetadata.encoded(metadata.1, using: encoder.1),
        ]
    }
}

public struct CompositeMetadataEncoderTuple3<A, B, C>: CompositeMetadataEncoder where
A: MetadataEncoder,
B: MetadataEncoder,
C: MetadataEncoder
{
    public typealias Metadata = (A.Metadata, B.Metadata, C.Metadata)
    let encoder: (A, B, C)
    public func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata] {
        [
            try CompositeMetadata.encoded(metadata.0, using: encoder.0),
            try CompositeMetadata.encoded(metadata.1, using: encoder.1),
            try CompositeMetadata.encoded(metadata.2, using: encoder.2),
        ]
    }
}


@resultBuilder
public enum CompositeMetadataEncoderBuilder {
    public static func buildBlock<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: CompositeMetadataEncoder {
        encoder
    }
    public static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> CompositeMetadataEncoderTuple2<A, B> {
        .init(encoder: (a, b))
    }
    public static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> CompositeMetadataEncoderTuple3<A, B, C> {
        .init(encoder: (a, b, c))
    }
}

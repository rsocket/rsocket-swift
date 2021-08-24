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
import NIOCore

public protocol CompositeMetadataDecoder {
    associatedtype Metadata
    func decode(from compositeMetadata: [CompositeMetadata]) throws -> Metadata
}


public struct CompositeMetadataDecoderTuple2<A, B>: CompositeMetadataDecoder where
A: MetadataDecoder,
B: MetadataDecoder
{
    public typealias Metadata = (A.Metadata, B.Metadata)
    @usableFromInline
    internal let decoder: (A, B)
    
    @inlinable
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
    
    @usableFromInline
    internal let decoder: (A, B, C)
    
    @inlinable
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
    public static func buildLimitedAvailability<T>(_ component: T) -> T {
        component
    }
    public static func buildEither<T>(first component: T) -> T {
        component
    }
    public static func buildEither<T>(second component: T) -> T {
        component
    }
}

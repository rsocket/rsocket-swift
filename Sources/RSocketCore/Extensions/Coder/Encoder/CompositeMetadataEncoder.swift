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

public protocol CompositeMetadataEncoder {
    associatedtype Metadata
    func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata]
}

public struct CompositeMetadataEncoderTuple2<A, B>: CompositeMetadataEncoder where
A: MetadataEncoder,
B: MetadataEncoder
{
    public typealias Metadata = (A.Metadata, B.Metadata)
    
    @usableFromInline
    internal let encoder: (A, B)
    
    @inlinable
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
    
    @usableFromInline
    internal let encoder: (A, B, C)
    
    @inlinable
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

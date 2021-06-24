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

protocol MetadataEncodable {
    associatedtype CombinableMetadata = Void
    static func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata,
        using metadataEncoder: Encoder
    ) throws -> Self where Encoder: MetadataEncoder
    static func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata,
        using metadataEncoder: Encoder,
        combinedWith other: CombinableMetadata
    ) throws -> Self where Encoder: MetadataEncoder
}

extension MetadataEncodable where CombinableMetadata == Void {
    static func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata, 
        using metadataEncoder: Encoder, 
        combinedWith other: Void
    ) throws -> Self where Encoder : MetadataEncoder {
        try encodeMetadata(metadata, using: metadataEncoder)
    }
}

extension Data: MetadataEncodable {
    static func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata, 
        using metadataEncoder: Encoder
    ) throws -> Data where Encoder : MetadataEncoder {
        try metadataEncoder.encode(metadata)
    }
}

extension Optional: MetadataEncodable where Wrapped: MetadataEncodable {
    static func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata, 
        using metadataEncoder: Encoder
    ) throws -> Self where Encoder : MetadataEncoder {
        try Wrapped.encodeMetadata(metadata, using: metadataEncoder)
    }
}

extension Array: MetadataEncodable where Element == CompositeMetadata {
    static func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata, 
        using metadataEncoder: Encoder
    ) throws -> Self where Encoder : MetadataEncoder {
        [try CompositeMetadata.encoded(metadata, using: metadataEncoder)]
    }
    static func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata, 
        using metadataEncoder: Encoder, 
        combinedWith other: Self
    ) throws -> [CompositeMetadata] where Encoder : MetadataEncoder {
        other + CollectionOfOne(try CompositeMetadata.encoded(metadata, using: metadataEncoder))
    }
}

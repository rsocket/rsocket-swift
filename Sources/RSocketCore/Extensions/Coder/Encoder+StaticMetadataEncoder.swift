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

extension Encoders {
    public struct StaticMetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata: MetadataEncodable,
    MetadataEncoder: RSocketCore.MetadataEncoder
    {
        public typealias Metadata = Encoder.Metadata.CombinableMetadata
        public typealias Data = Encoder.Data
        
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let metadataEncoder: MetadataEncoder
        
        @usableFromInline
        internal let staticMetadata: MetadataEncoder.Metadata
        
        @usableFromInline
        internal init(encoder: Encoder, metadataEncoder: MetadataEncoder, staticMetadata: MetadataEncoder.Metadata) {
            self.encoder = encoder
            self.metadataEncoder = metadataEncoder
            self.staticMetadata = staticMetadata
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
                metadata: try Encoder.Metadata.encodeMetadata(
                    staticMetadata, 
                    using: metadataEncoder, 
                    combinedWith: metadata
                ), 
                data: data, 
                mimeType: mimeType
            )
        }
    }
}

extension EncoderProtocol {
    /// adds the given metadata to the composition
    @inlinable
    public func encodeStaticMetadata<MetadataEncoder>(
        _ staticMetadata: MetadataEncoder.Metadata,
        using metadataEncoder: MetadataEncoder
    ) -> Encoders.StaticMetadataEncoder<Self, MetadataEncoder> {
        .init(encoder: self, metadataEncoder: metadataEncoder, staticMetadata: staticMetadata)
    }
}

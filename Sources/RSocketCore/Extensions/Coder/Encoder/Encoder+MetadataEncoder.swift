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
    public struct MetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata: MetadataEncodable,
    MetadataEncoder: RSocketCore.MetadataEncoder
    {
        public typealias Metadata = MetadataEncoder.Metadata
        public typealias Data = Encoder.Data
        
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let metadataEncoder: MetadataEncoder
        
        @usableFromInline
        internal init(encoder: Encoder, metadataEncoder: MetadataEncoder) {
            self.encoder = encoder
            self.metadataEncoder = metadataEncoder
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
                metadata: try Encoder.Metadata.encodeMetadata(metadata, using: metadataEncoder), 
                data: data, 
                mimeType: mimeType
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func encodeMetadata<MetadataEncoder>(
        using metadataEncoder: MetadataEncoder
    ) -> Encoders.MetadataEncoder<Self, MetadataEncoder> {
        .init(encoder: self, metadataEncoder: metadataEncoder)
    }
}



extension Encoders {
    public typealias RootCompositeMetadataEncoder<Encoder> = 
        MetadataEncoder<Encoder, RSocketCore.RootCompositeMetadataEncoder> where 
        Encoder: EncoderProtocol, 
        Encoder.Metadata == Foundation.Data?
}

extension EncoderProtocol {
    @inlinable
    public func useCompositeMetadata(
        metadataEncoder: RootCompositeMetadataEncoder = .init()
    ) -> Encoders.RootCompositeMetadataEncoder<Self> where Metadata == Foundation.Data? {
        encodeMetadata(using: metadataEncoder)
    }
}

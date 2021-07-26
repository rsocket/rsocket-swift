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

extension Decoders {
    public struct MetadataDecoder<Decoder, MetadataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata: MetadataDecodable,
    MetadataDecoder: RSocketCore.MetadataDecoder
    {
        public typealias Metadata = MetadataDecoder.Metadata?
        public typealias Data = Decoder.Data
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let metadataDecoder: MetadataDecoder
        
        @usableFromInline
        internal init(decoder: Decoder, metadataDecoder: MetadataDecoder) {
            self.decoder = decoder
            self.metadataDecoder = metadataDecoder
        }
        
        @inlinable
        public mutating func decode(
            _ payload: Payload,
            encoding: ConnectionEncoding
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, encoding: encoding)
            let decodedMetadata = try metadata.decodeMetadata(using: metadataDecoder)
            return (decodedMetadata, data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func decodeMetadata<MetadataDecoder>(
        using metadataDecoder: MetadataDecoder
    ) -> Decoders.MetadataDecoder<Self, MetadataDecoder> {
        .init(decoder: self, metadataDecoder: metadataDecoder)
    }
}

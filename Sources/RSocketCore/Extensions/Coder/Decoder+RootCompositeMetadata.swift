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
    public struct RootCompositeMetadataDecoder<Decoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata == Foundation.Data?
    {
        public typealias Metadata = [CompositeMetadata]
        public typealias Data = Decoder.Data
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let metadataDecoder: RSocketCore.RootCompositeMetadataDecoder
        
        @usableFromInline
        internal init(decoder: Decoder, metadataDecoder: RSocketCore.RootCompositeMetadataDecoder) {
            self.decoder = decoder
            self.metadataDecoder = metadataDecoder
        }
        
        @inlinable
        mutating public func decode(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            let decodedMetadata = try metadata.map { try metadataDecoder.decode(from: $0) }
            return (decodedMetadata ?? [], data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func useCompositeMetadata(
        metadataDecoder: RootCompositeMetadataDecoder = .init()
    ) -> Decoders.RootCompositeMetadataDecoder<Self> where Metadata == Foundation.Data? {
        .init(decoder: self, metadataDecoder: metadataDecoder)
    }
}

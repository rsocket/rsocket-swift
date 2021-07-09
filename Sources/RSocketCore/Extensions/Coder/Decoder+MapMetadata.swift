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
    public struct MapMetadata<Decoder: DecoderProtocol, Metadata>: DecoderProtocol {
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let transform: (Decoder.Metadata) throws -> Metadata
        
        @usableFromInline
        internal init(
            decoder: Decoder, 
            transform: @escaping (Decoder.Metadata) throws -> Metadata
        ) {
            self.decoder = decoder
            self.transform = transform
        }
        
        @inlinable
        public mutating func decode(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Decoder.Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            return (try transform(metadata), data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func mapMetadata<NewMetadata>(
        _ transform: @escaping (Metadata) throws -> NewMetadata
    ) -> Decoders.MapMetadata<Self, NewMetadata> {
        .init(decoder: self, transform: transform)
    }
}

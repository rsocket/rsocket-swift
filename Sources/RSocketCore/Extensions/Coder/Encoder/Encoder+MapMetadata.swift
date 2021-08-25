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


extension Encoders {
    public struct MapMetadata<Encoder: EncoderProtocol, Metadata>: EncoderProtocol {
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let transform: (Metadata) throws -> Encoder.Metadata
        
        @usableFromInline
        internal init(encoder: Encoder, transform: @escaping (Metadata) throws -> Encoder.Metadata) {
            self.encoder = encoder
            self.transform = transform
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Encoder.Data,
            encoding: ConnectionEncoding
        ) throws -> Payload {
            try encoder.encode(metadata: try transform(metadata), data: data, encoding: encoding)
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func mapMetadata<NewMetadata>(
        _ transform: @escaping (NewMetadata) throws -> Metadata
    ) -> Encoders.MapMetadata<Self, NewMetadata> {
        .init(encoder: self, transform: transform)
    }
}

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
    public struct Map<Encoder: EncoderProtocol, Metadata, Data>: EncoderProtocol {
        @usableFromInline 
        internal var encoder: Encoder
        
        @usableFromInline
        internal let transform: (Metadata, Data) throws -> (Encoder.Metadata, Encoder.Data)
        
        @usableFromInline
        internal init(
            encoder: Encoder, 
            transform: @escaping (Metadata, Data) throws -> (Encoder.Metadata, Encoder.Data)
        ) {
            self.encoder = encoder
            self.transform = transform
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            encoding: ConnectionEncoding
        ) throws -> Payload {
            let (metadata, data) = try transform(metadata, data)
            return try encoder.encode(metadata: metadata, data: data, encoding: encoding)
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func map<NewMetadata, NewData>(
        _ transform: @escaping (NewMetadata, NewData) throws -> (Metadata, Data)
    ) -> Encoders.Map<Self, NewMetadata, NewData> {
        .init(encoder: self, transform: transform)
    }
}

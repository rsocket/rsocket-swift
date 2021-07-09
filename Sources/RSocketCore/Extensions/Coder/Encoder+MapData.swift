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
    public struct MapData<Encoder: EncoderProtocol, Data>: EncoderProtocol {
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let transform: (Data) throws -> Encoder.Data
        
        @usableFromInline
        internal init(encoder: Encoder, transform: @escaping (Data) throws -> Encoder.Data) {
            self.encoder = encoder
            self.transform = transform
        }
        
        @inlinable
        mutating public func encode(
            metadata: Encoder.Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(metadata: metadata, data: try transform(data), mimeType: mimeType)
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func mapData<NewData>(
        _ transform: @escaping (NewData) throws -> Data
    ) -> Encoders.MapData<Self, NewData> {
        .init(encoder: self, transform: transform)
    }
}

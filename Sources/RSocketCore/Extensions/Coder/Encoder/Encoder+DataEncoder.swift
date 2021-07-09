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
    public struct DataEncoder<Encoder, DataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Data == Data,
    DataEncoder: RSocketCore.DataEncoderProtocol
    {
        public typealias Metadata = Encoder.Metadata
        public typealias Data = DataEncoder.Data
        
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let dataEncoder: DataEncoder
        
        @usableFromInline
        internal init(encoder: Encoder, dataEncoder: DataEncoder) {
            self.encoder = encoder
            self.dataEncoder = dataEncoder
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
                metadata: metadata, 
                data: try dataEncoder.encode(data), 
                mimeType: mimeType
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func encodeData<DataEncoder>(
        using dataEncoder: DataEncoder
    ) -> Encoders.DataEncoder<Self, DataEncoder> {
        .init(encoder: self, dataEncoder: dataEncoder)
    }
}

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
    public struct MultiDataEncoder<Encoder, DataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Data == Foundation.Data,
    Encoder.Metadata == [CompositeMetadata],
    DataEncoder: RSocketCore.MultiDataEncoderProtocol
    {
        public typealias Metadata = Encoder.Metadata
        public typealias Data = (MIMEType, DataEncoder.Data)
        
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let dataEncoder: DataEncoder
        
        @usableFromInline
        internal let dataMIMETypeEncoder: DataMIMETypeEncoder
        
        @usableFromInline
        internal let alwaysEncodeDataMIMEType: Bool
        
        @usableFromInline
        internal init(
            encoder: Encoder, 
            dataEncoder: DataEncoder, 
            dataMIMETypeEncoder: DataMIMETypeEncoder, 
            alwaysEncodeDataMIMEType: Bool
        ) {
            self.encoder = encoder
            self.dataEncoder = dataEncoder
            self.dataMIMETypeEncoder = dataMIMETypeEncoder
            self.alwaysEncodeDataMIMEType = alwaysEncodeDataMIMEType
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            encoding: ConnectionEncoding
        ) throws -> Payload {
            let (dataMIMEType, data) = data
            
            let shouldEncodeDataMIMEType = alwaysEncodeDataMIMEType || 
                encoding.data != dataMIMEType
            let newMetadata: [CompositeMetadata]
            if shouldEncodeDataMIMEType {
                newMetadata = try metadata.encoded(dataMIMEType, using: dataMIMETypeEncoder)
            } else {
                newMetadata = metadata
            }
            return try encoder.encode(
                metadata: newMetadata, 
                data: try dataEncoder.encode(data, as: dataMIMEType), 
                encoding: encoding
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func encodeData<Encoder>(
        alwaysEncodeDataMIMEType: Bool = false,
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init(),
        @MultiDataEncoderBuilder encoder: () -> Encoder
    ) -> Encoders.MultiDataEncoder<Self, Encoder> {
        .init(encoder: self, dataEncoder: encoder(), dataMIMETypeEncoder: dataMIMETypeEncoder, alwaysEncodeDataMIMEType: alwaysEncodeDataMIMEType)
    }
}

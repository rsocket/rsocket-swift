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
    public struct MultiDataDecoder<Decoder, DataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata == [CompositeMetadata],
    Decoder.Data == Foundation.Data,
    DataDecoder: MultiDataDecoderProtocol
    {
        public typealias Metadata = Decoder.Metadata
        public typealias Data = DataDecoder.Data
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let dataMIMETypeDecoder: DataMIMETypeDecoder
        
        @usableFromInline
        internal let dataDecoder: DataDecoder
        
        @usableFromInline
        internal var lastSeenDataMIMEType: MIMEType?
        
        @inlinable
        internal init(
            decoder: Decoder, 
            dataMIMETypeDecoder: DataMIMETypeDecoder, 
            dataDecoder: DataDecoder, 
            lastSeenDataMIMEType: MIMEType? = nil
        ) {
            self.decoder = decoder
            self.dataMIMETypeDecoder = dataMIMETypeDecoder
            self.dataDecoder = dataDecoder
            self.lastSeenDataMIMEType = lastSeenDataMIMEType
        }
        
        @inlinable
        mutating public func decode(
            _ payload: Payload,
            encoding: ConnectionEncoding
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, encoding: encoding)
            if let dataMIMEType = try metadata.decodeFirstIfPresent(using: dataMIMETypeDecoder) {
                lastSeenDataMIMEType = dataMIMEType
            }
            let dataMIMEType = lastSeenDataMIMEType ?? encoding.data
            let decodedData = try dataDecoder.decodeMIMEType(dataMIMEType, from: data)
            return (metadata, decodedData)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func decodeData<DataDecoder>(
        dataMIMETypeDecoder: DataMIMETypeDecoder = .init(),
        @MultiDataDecoderBuilder dataDecoder: () -> DataDecoder
    ) -> Decoders.MultiDataDecoder<Self, DataDecoder> {
        .init(decoder: self, dataMIMETypeDecoder: dataMIMETypeDecoder, dataDecoder: dataDecoder())
    }
}

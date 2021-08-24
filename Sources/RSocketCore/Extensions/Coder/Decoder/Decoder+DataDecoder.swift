
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

import NIOCore

extension Decoders {
    public struct DataDecoder<Decoder, DataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Data == ByteBuffer,
    DataDecoder: DataDecoderProtocol
    {
        public typealias Metadata = Decoder.Metadata
        public typealias Data = DataDecoder.Data
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let dataDecoder: DataDecoder
        
        @usableFromInline
        internal init(decoder: Decoder, dataDecoder: DataDecoder) {
            self.decoder = decoder
            self.dataDecoder = dataDecoder
        }
        
        @inlinable
        mutating public func decode(
            _ payload: Payload,
            encoding: ConnectionEncoding
        ) throws -> (Metadata, Data) {
            var (metadata, data) = try decoder.decode(payload, encoding: encoding)
            let decodedData = try dataDecoder.decode(from: &data)
            return (metadata, decodedData)
        }
    }
}

extension DecoderProtocol {
    /// unconditionally decodes data with the given `decoder`
    @inlinable
    public func decodeData<DataDecoder>(
        using dataDecoder: DataDecoder
    ) -> Decoders.DataDecoder<Self, DataDecoder> {
        .init(decoder: self, dataDecoder: dataDecoder)
    }
}

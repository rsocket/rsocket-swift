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

public struct Coder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    public let decoder: Decoder
    public let encoder: Encoder
}

extension Coder {
    public init() where
    Decoder == RSocketCore.Decoder,
    Encoder == RSocketCore.Encoder
    {
        self.init(decoder: .init(), encoder: .init())
    }
}

public extension Coder {
    func mapDecoder<NewDecoder>(
        _ transform: (Decoder) -> NewDecoder
    ) -> Coder<NewDecoder, Encoder> {
        .init(decoder: transform(decoder), encoder: encoder)
    }
    func mapEncoder<NewEncoder>(
        _ transform: (Encoder) -> NewEncoder
    ) -> Coder<Decoder, NewEncoder> {
        .init(decoder: decoder, encoder: transform(encoder))
    }
}

public extension Coder {
    /// Decodes data using one of the given `decoder`s, depending on the MIME Type of the Data.
    ///
    /// In addition, this methods encodes all MIME Types of all `decoder`s using the given `acceptableDataMIMETypeEncoder`.
    /// This makes it possible for a requester to support multiple response data MIME Types at the same time and let the responder choose the best one.
    func decodeData<DataDecoder>(
        acceptableDataMIMETypeEncoder: AcceptableDataMIMETypeEncoder = .init(),
        dataMIMETypeDecoder: DataMIMETypeDecoder = .init(),
        @MultiDataDecoderBuilder decoder: () -> DataDecoder
    ) -> Coder<
        Decoders.MultiDataDecoder<Decoder, DataDecoder>, 
        Encoders.StaticMetadataEncoder<Encoder, AcceptableDataMIMETypeEncoder>
    > {
        let decoder = decoder()
        let supportedEncodings = decoder.supportedMIMETypes
        return mapEncoder{
            $0.encodeStaticMetadata(supportedEncodings, using: acceptableDataMIMETypeEncoder)
        }.mapDecoder{
            $0.decodeData(dataMIMETypeDecoder: dataMIMETypeDecoder, dataDecoder: { decoder })
        }
    }
}

// MARK: - Coder decode and encode convenience methods

public extension Coder where Decoder.Metadata == Data?, Encoder.Metadata == Data? {
    func useCompositeMetadata(
        metadataDecoder: RootCompositeMetadataDecoder = .init(),
        metadataEncoder: RootCompositeMetadataEncoder = .init()
    ) -> Coder<
        Decoders.RootCompositeMetadataDecoder<Decoder>,
        Encoders.RootCompositeMetadataEncoder<Encoder>
    > {
        mapDecoder { $0.useCompositeMetadata(metadataDecoder: metadataDecoder) }
        .mapEncoder { $0.useCompositeMetadata(metadataEncoder: metadataEncoder) }
    }
}

// MARK: - Coder decode convenience methods

public extension Coder {
    func decodeMetadata<MetadataDecoder>(
        using metadataDecoder: MetadataDecoder
    ) -> Coder<Decoders.MetadataDecoder<Decoder, MetadataDecoder>, Encoder> {
        mapDecoder { $0.decodeMetadata(using: metadataDecoder) }
    }
    func decodeMetadata<CompositeMetadataDecoder>(
        @CompositeMetadataDecoderBuilder metadataDecoder: () -> CompositeMetadataDecoder
    ) -> Coder<Decoders.CompositeMetadataDecoder<Decoder, CompositeMetadataDecoder>, Encoder> {
        mapDecoder { $0.decodeMetadata(metadataDecoder: metadataDecoder) }
    }
    /// unconditionally decodes data with the given `decoder`
    func decodeData<DataDecoder>(
        using dataDecoder: DataDecoder
    ) -> Coder<Decoders.DataDecoder<Decoder, DataDecoder>, Encoder> {
        mapDecoder { $0.decodeData(using: dataDecoder) }
    }
}

// MARK: - Coder encode convenience methods

public extension Coder {
    func encodeMetadata<MetadataEncoder>(
        using metadataEncoder: MetadataEncoder
    ) -> Coder<Decoder, Encoders.MetadataEncoder<Encoder, MetadataEncoder>> {
        mapEncoder { $0.encodeMetadata(using: metadataEncoder) }
    }
    func encodeMetadata<CompositeMetadataEncoder>(
        @CompositeMetadataEncoderBuilder metadataEncoder: () -> CompositeMetadataEncoder
    ) -> Coder<Decoder, Encoders.CompositeMetadataEncoder<Encoder, CompositeMetadataEncoder>> {
        mapEncoder { $0.encodeMetadata(metadataEncoder: metadataEncoder) }
    }
    func encodeStaticMetadata<MetadataEncoder>(
        _ staticMetadata: MetadataEncoder.Metadata,
        using metadataEncoder: MetadataEncoder
    ) -> Coder<Decoder, Encoders.StaticMetadataEncoder<Encoder, MetadataEncoder>> {
        mapEncoder { $0.encodeStaticMetadata(staticMetadata, using: metadataEncoder) }
    }
    
    func encodeData<DataEncoder>(
        using dataEncoder: DataEncoder
    ) -> Coder<Decoder, Encoders.DataEncoder<Encoder, DataEncoder>> {
        mapEncoder { $0.encodeData(using: dataEncoder) }
    }
    func encodeData<DataEncoder>(
        alwaysEncodeDataMIMEType: Bool = false,
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init(),
        @MultiDataEncoderBuilder encoder: () -> DataEncoder
    ) -> Coder<Decoder, Encoders.MultiDataEncoder<Encoder, DataEncoder>> {
        mapEncoder { 
            $0.encodeData(
                alwaysEncodeDataMIMEType: alwaysEncodeDataMIMEType,
                dataMIMETypeEncoder: dataMIMETypeEncoder, 
                encoder: encoder
            ) 
        }
    }
}

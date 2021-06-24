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

public protocol DecoderProtocol {
    associatedtype Metadata
    associatedtype Data
    mutating func decodedPayload(
        _ payload: Payload,
        mimeType: ConnectionMIMEType
    ) throws -> (Metadata, Data)
}


public struct Decoder: DecoderProtocol {
    public init() {}
    public func decodedPayload(
        _ payload: Payload, 
        mimeType: ConnectionMIMEType
    ) throws -> (Data?, Data) {
        (payload.metadata, payload.data)
    }
}

public struct AnyDecoder<Metadata, Data>: DecoderProtocol {
    var _decoderBox: _AnyDecoderBase<Metadata, Data>
    init<Decoder>(
        _ decoder: Decoder
    ) where Decoder: DecoderProtocol, Decoder.Metadata == Metadata, Decoder.Data == Data {
        _decoderBox = _AnyDecoderBox(decoder: decoder)
    }
    public mutating func decodedPayload(
        _ payload: Payload,
        mimeType: ConnectionMIMEType
    ) throws -> (Metadata, Data) {
        if !isKnownUniquelyReferenced(&_decoderBox) {
            _decoderBox = _decoderBox.copy()
        }
        return try _decoderBox.decodedPayload(payload, mimeType: mimeType)
    }
}

class _AnyDecoderBase<Metadata, Data>: DecoderProtocol {
    func decodedPayload(
        _ payload: Payload,
        mimeType: ConnectionMIMEType
    ) throws -> (Metadata, Data) {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
    func copy() -> _AnyDecoderBase<Metadata, Data> {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
}

final class _AnyDecoderBox<Decoder: DecoderProtocol>: _AnyDecoderBase<Decoder.Metadata, Decoder.Data> {
    var decoder: Decoder
    internal init(decoder: Decoder) {
        self.decoder = decoder
    }
    override func decodedPayload(
        _ payload: Payload,
        mimeType: ConnectionMIMEType
    ) throws -> (Decoder.Metadata, Decoder.Data) {
        try decoder.decodedPayload(payload, mimeType: mimeType)
    }
    override func copy() -> _AnyDecoderBase<Decoder.Metadata, Decoder.Data> {
        _AnyDecoderBox(decoder: decoder)
    }
}

extension DecoderProtocol {
    public func eraseToAnyDecoder() -> AnyDecoder<Metadata, Data> {
        .init(self)
    }
}


/// Namespace for types conforming to the ``DecoderProtocol`` protocol
public enum Decoders {}

public extension Decoders {
    struct Map<Decoder: DecoderProtocol, Metadata, Data>: DecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Metadata, Decoder.Data) throws -> (Metadata, Data)
        public mutating func decodedPayload(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: mimeType)
            return try transform(metadata, data)
        }
    }
    struct MapMetadata<Decoder: DecoderProtocol, Metadata>: DecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Metadata) throws -> Metadata
        public mutating func decodedPayload(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Decoder.Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: mimeType)
            return (try transform(metadata), data)
        }
    }
    struct MapData<Decoder: DecoderProtocol, Data>: DecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Data) throws -> Data
        public mutating func decodedPayload(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Decoder.Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: mimeType)
            return (metadata, try transform(data))
        }
    }
    struct MetadataDecoder<Decoder, MetadataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata: MetadataDecodable,
    MetadataDecoder: RSocketCore.MetadataDecoder
    {
        public typealias Metadata = MetadataDecoder.Metadata?
        public typealias Data = Decoder.Data
        var decoder: Decoder
        var metadataDecoder: MetadataDecoder
        public mutating func decodedPayload(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: mimeType)
            let decodedMetadata = try metadata.decodeMetadata(using: metadataDecoder)
            return (decodedMetadata, data)
        }
    }
    struct CompositeMetadataDecoder<Decoder, CompositeMetadataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata == [CompositeMetadata],
    CompositeMetadataDecoder: RSocketCore.CompositeMetadataDecoder
    {
        public typealias Metadata = CompositeMetadataDecoder.Metadata
        public typealias Data = Decoder.Data
        var decoder: Decoder
        var metadataDecoder: CompositeMetadataDecoder
        mutating public func decodedPayload(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: mimeType)
            let decodedMetadata = try metadataDecoder.decode(from: metadata)
            return (decodedMetadata, data)
        }
    }
    struct RootCompositeMetadataDecoder<Decoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata == Foundation.Data?
    {
        public typealias Metadata = [CompositeMetadata]
        public typealias Data = Decoder.Data
        var decoder: Decoder
        var metadataDecoder: RSocketCore.RootCompositeMetadataDecoder
        mutating public func decodedPayload(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: mimeType)
            let decodedMetadata = try metadata.map { try metadataDecoder.decode(from: $0) }
            return (decodedMetadata ?? [], data)
        }
    }
    struct DataDecoder<Decoder, DataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Data == Foundation.Data,
    DataDecoder: DataDecoderProtocol
    {
        public typealias Metadata = Decoder.Metadata
        public typealias Data = DataDecoder.Data
        var decoder: Decoder
        var dataDecoder: DataDecoder
        mutating public func decodedPayload(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: mimeType)
            let decodedData = try dataDecoder.decode(from: data)
            return (metadata, decodedData)
        }
    }
    struct MultiDataDecoder<Decoder, DataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata == [CompositeMetadata],
    Decoder.Data == Foundation.Data,
    DataDecoder: MultiDataDecoderProtocol
    {
        public typealias Metadata = Decoder.Metadata
        public typealias Data = DataDecoder.Data
        var decoder: Decoder
        var dataMIMETypeDecoder: DataMIMETypeDecoder
        var dataDecoder: DataDecoder
        var lastSeenDataMIMEType: MIMEType?
        mutating public func decodedPayload(
            _ payload: Payload,
            mimeType connectionMIMEType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload, mimeType: connectionMIMEType)
            if let dataMIMEType = try metadata.decodeFirstIfPresent(using: dataMIMETypeDecoder) {
                lastSeenDataMIMEType = dataMIMEType
            }
            let dataMIMEType = lastSeenDataMIMEType ?? connectionMIMEType.data
            let decodedData = try dataDecoder.decodeMIMEType(dataMIMEType, from: data)
            return (metadata, decodedData)
        }
    }
}

public extension DecoderProtocol {
    func map<NewMetadata, NewData>(
        _ transform: @escaping (Metadata, Data) throws -> (NewMetadata, NewData)
    ) -> Decoders.Map<Self, NewMetadata, NewData> {
        .init(decoder: self, transform: transform)
    }
    func mapMetadata<NewMetadata>(
        _ transform: @escaping (Metadata) throws -> NewMetadata
    ) -> Decoders.MapMetadata<Self, NewMetadata> {
        .init(decoder: self, transform: transform)
    }
    func mapData<NewData>(
        _ transform: @escaping (Data) throws -> NewData
    ) -> Decoders.MapData<Self, NewData> {
        .init(decoder: self, transform: transform)
    }
    func decodeMetadata<MetadataDecoder>(
        using metadataDecoder: MetadataDecoder
    ) -> Decoders.MetadataDecoder<Self, MetadataDecoder> {
        .init(decoder: self, metadataDecoder: metadataDecoder)
    }
    func decodeMetadata<CompositeMetadataDecoder>(
        @CompositeMetadataDecoderBuilder metadataDecoder: () -> CompositeMetadataDecoder
    ) -> Decoders.CompositeMetadataDecoder<Self, CompositeMetadataDecoder> {
        .init(decoder: self, metadataDecoder: metadataDecoder())
    }
    /// unconditionally decodes data with the given `decoder`
    func decodeData<DataDecoder>(
        using dataDecoder: DataDecoder
    ) -> Decoders.DataDecoder<Self, DataDecoder> {
        .init(decoder: self, dataDecoder: dataDecoder)
    }
    /// unconditionally decodes data with the given `decoder`
    func decodeData<DataDecoder>(
        dataMIMETypeDecoder: DataMIMETypeDecoder = .init(),
        @MultiDataDecoderBuilder dataDecoder: () -> DataDecoder
    ) -> Decoders.MultiDataDecoder<Self, DataDecoder> {
        .init(decoder: self, dataMIMETypeDecoder: dataMIMETypeDecoder, dataDecoder: dataDecoder())
    }
    func useCompositeMetadata(
        metadataDecoder: RootCompositeMetadataDecoder = .init()
    ) -> Decoders.RootCompositeMetadataDecoder<Self> where Metadata == Foundation.Data? {
        .init(decoder: self, metadataDecoder: metadataDecoder)
    }
}

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
    mutating func decode(
        _ payload: Payload,
        mimeType: ConnectionMIMEType
    ) throws -> (Metadata, Data)
}


public struct Decoder: DecoderProtocol {
    @inlinable
    public init() {}
    
    @inlinable
    public func decode(
        _ payload: Payload, 
        mimeType: ConnectionMIMEType
    ) throws -> (Data?, Data) {
        (payload.metadata, payload.data)
    }
}


/// Namespace for types conforming to the ``DecoderProtocol`` protocol
public enum Decoders {}

extension Decoders {
    public struct Map<Decoder: DecoderProtocol, Metadata, Data>: DecoderProtocol {
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let transform: (Decoder.Metadata, Decoder.Data) throws -> (Metadata, Data)
        
        @usableFromInline
        internal init(
            decoder: Decoder, 
            transform: @escaping (Decoder.Metadata, Decoder.Data) throws -> (Metadata, Data)
        ) {
            self.decoder = decoder
            self.transform = transform
        }
        
        @inlinable
        public mutating func decode(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            return try transform(metadata, data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func map<NewMetadata, NewData>(
        _ transform: @escaping (Metadata, Data) throws -> (NewMetadata, NewData)
    ) -> Decoders.Map<Self, NewMetadata, NewData> {
        .init(decoder: self, transform: transform)
    }
}


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


extension Decoders {
    public struct MapData<Decoder: DecoderProtocol, Data>: DecoderProtocol {
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let transform: (Decoder.Data) throws -> Data
        
        @usableFromInline
        internal init(
            decoder: Decoder, 
            transform: @escaping (Decoder.Data) throws -> Data
        ) {
            self.decoder = decoder
            self.transform = transform
        }
        
        @inlinable
        public mutating func decode(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Decoder.Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            return (metadata, try transform(data))
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func mapData<NewData>(
        _ transform: @escaping (Data) throws -> NewData
    ) -> Decoders.MapData<Self, NewData> {
        .init(decoder: self, transform: transform)
    }
}


extension Decoders {
    public struct MetadataDecoder<Decoder, MetadataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata: MetadataDecodable,
    MetadataDecoder: RSocketCore.MetadataDecoder
    {
        public typealias Metadata = MetadataDecoder.Metadata?
        public typealias Data = Decoder.Data
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let metadataDecoder: MetadataDecoder
        
        @usableFromInline
        internal init(decoder: Decoder, metadataDecoder: MetadataDecoder) {
            self.decoder = decoder
            self.metadataDecoder = metadataDecoder
        }
        
        @inlinable
        public mutating func decode(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            let decodedMetadata = try metadata.decodeMetadata(using: metadataDecoder)
            return (decodedMetadata, data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func decodeMetadata<MetadataDecoder>(
        using metadataDecoder: MetadataDecoder
    ) -> Decoders.MetadataDecoder<Self, MetadataDecoder> {
        .init(decoder: self, metadataDecoder: metadataDecoder)
    }
}

extension Decoders {
    public struct CompositeMetadataDecoder<Decoder, CompositeMetadataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata == [CompositeMetadata],
    CompositeMetadataDecoder: RSocketCore.CompositeMetadataDecoder
    {
        public typealias Metadata = CompositeMetadataDecoder.Metadata
        public typealias Data = Decoder.Data
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let metadataDecoder: CompositeMetadataDecoder
        
        @usableFromInline
        internal init(
            decoder: Decoder, 
            metadataDecoder: CompositeMetadataDecoder
        ) {
            self.decoder = decoder
            self.metadataDecoder = metadataDecoder
        }
        
        @inlinable
        mutating public func decode(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            let decodedMetadata = try metadataDecoder.decode(from: metadata)
            return (decodedMetadata, data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func decodeMetadata<CompositeMetadataDecoder>(
        @CompositeMetadataDecoderBuilder metadataDecoder: () -> CompositeMetadataDecoder
    ) -> Decoders.CompositeMetadataDecoder<Self, CompositeMetadataDecoder> {
        .init(decoder: self, metadataDecoder: metadataDecoder())
    }
}


extension Decoders {
    public struct RootCompositeMetadataDecoder<Decoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Metadata == Foundation.Data?
    {
        public typealias Metadata = [CompositeMetadata]
        public typealias Data = Decoder.Data
        
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal let metadataDecoder: RSocketCore.RootCompositeMetadataDecoder
        
        @usableFromInline
        internal init(decoder: Decoder, metadataDecoder: RSocketCore.RootCompositeMetadataDecoder) {
            self.decoder = decoder
            self.metadataDecoder = metadataDecoder
        }
        
        @inlinable
        mutating public func decode(
            _ payload: Payload,
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            let decodedMetadata = try metadata.map { try metadataDecoder.decode(from: $0) }
            return (decodedMetadata ?? [], data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func useCompositeMetadata(
        metadataDecoder: RootCompositeMetadataDecoder = .init()
    ) -> Decoders.RootCompositeMetadataDecoder<Self> where Metadata == Foundation.Data? {
        .init(decoder: self, metadataDecoder: metadataDecoder)
    }
}


extension Decoders {
    public struct DataDecoder<Decoder, DataDecoder>: DecoderProtocol where
    Decoder: DecoderProtocol,
    Decoder.Data == Foundation.Data,
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
            mimeType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: mimeType)
            let decodedData = try dataDecoder.decode(from: data)
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
            mimeType connectionMIMEType: ConnectionMIMEType
        ) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decode(payload, mimeType: connectionMIMEType)
            if let dataMIMEType = try metadata.decodeFirstIfPresent(using: dataMIMETypeDecoder) {
                lastSeenDataMIMEType = dataMIMEType
            }
            let dataMIMEType = lastSeenDataMIMEType ?? connectionMIMEType.data
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

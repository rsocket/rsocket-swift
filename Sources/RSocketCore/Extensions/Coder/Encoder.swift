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

public protocol EncoderProtocol {
    associatedtype Metadata
    associatedtype Data
    mutating func encodedPayload(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload
}

/// Namespace for types conforming to the ``EncoderProtocol`` protocol
public enum Encoders {}

public extension Encoders {
    struct Map<Encoder: EncoderProtocol, Metadata, Data>: EncoderProtocol {
        var encoder: Encoder
        let transform: (Metadata, Data) throws -> (Encoder.Metadata, Encoder.Data)
        mutating public func encodedPayload(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            let (metadata, data) = try transform(metadata, data)
            return try encoder.encodedPayload(metadata: metadata, data: data, mimeType: mimeType)
        }
    }
    struct MapMetadata<Encoder: EncoderProtocol, Metadata>: EncoderProtocol {
        var encoder: Encoder
        let transform: (Metadata) throws -> Encoder.Metadata
        mutating public func encodedPayload(
            metadata: Metadata,
            data: Encoder.Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encodedPayload(metadata: try transform(metadata), data: data, mimeType: mimeType)
        }
    }
    struct MapData<Encoder: EncoderProtocol, Data>: EncoderProtocol {
        var encoder: Encoder
        let transform: (Data) throws -> Encoder.Data
        mutating public func encodedPayload(
            metadata: Encoder.Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encodedPayload(metadata: metadata, data: try transform(data), mimeType: mimeType)
        }
    }
    struct MetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata: MetadataEncodable,
    MetadataEncoder: RSocketCore.MetadataEncoder
    {
        public typealias Metadata = MetadataEncoder.Metadata
        public typealias Data = Encoder.Data
        var encoder: Encoder
        let metadataEncoder: MetadataEncoder
        mutating public func encodedPayload(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encodedPayload(
                metadata: try Encoder.Metadata.encodeMetadata(metadata, using: metadataEncoder), 
                data: data, 
                mimeType: mimeType
            )
        }
    }
    typealias RootCompositeMetadataEncoder<Encoder> = MetadataEncoder<Encoder, RSocketCore.RootCompositeMetadataEncoder> where Encoder: EncoderProtocol, Encoder.Metadata == Foundation.Data?
    
    struct StaticMetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata: MetadataEncodable,
    MetadataEncoder: RSocketCore.MetadataEncoder
    {
        public typealias Metadata = Encoder.Metadata.CombinableMetadata
        public typealias Data = Encoder.Data
        var encoder: Encoder
        let metadataEncoder: MetadataEncoder
        let staticMetadata: MetadataEncoder.Metadata
        mutating public func encodedPayload(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encodedPayload(
                metadata: try Encoder.Metadata.encodeMetadata(
                    staticMetadata, 
                    using: metadataEncoder, 
                    combinedWith: metadata
                ), 
                data: data, 
                mimeType: mimeType
            )
        }
    }
    struct CompositeMetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata == [CompositeMetadata],
    MetadataEncoder: RSocketCore.CompositeMetadataEncoder
    {
        public typealias Metadata = MetadataEncoder.Metadata
        public typealias Data = Encoder.Data
        var encoder: Encoder
        let metadataEncoder: MetadataEncoder
        mutating public func encodedPayload(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encodedPayload(
                metadata: metadataEncoder.encodeMetadata(metadata), 
                data: data, 
                mimeType: mimeType
            )
        }
    }
    struct DataEncoder<Encoder, DataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Data == Data,
    DataEncoder: RSocketCore.DataEncoderProtocol
    {
        public typealias Metadata = Encoder.Metadata
        public typealias Data = DataEncoder.Data
        var encoder: Encoder
        let dataEncoder: DataEncoder
        mutating public func encodedPayload(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encodedPayload(
                metadata: metadata, 
                data: try dataEncoder.encode(data), 
                mimeType: mimeType
            )
        }
    }
    struct MultiDataEncoder<Encoder, DataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Data == Foundation.Data,
    Encoder.Metadata == [CompositeMetadata],
    DataEncoder: RSocketCore.MultiDataEncoderProtocol
    {
        public typealias Metadata = Encoder.Metadata
        public typealias Data = (MIMEType, DataEncoder.Data)
        var encoder: Encoder
        let dataEncoder: DataEncoder
        let dataMIMETypeEncoder: DataMIMETypeEncoder
        let alwaysEncodeDataMIMEType: Bool
        mutating public func encodedPayload(
            metadata: Metadata,
            data: Data,
            mimeType connectionMIMEType: ConnectionMIMEType
        ) throws -> Payload {
            let (dataMIMEType, data) = data
            
            let shouldEncodeDataMIMEType = alwaysEncodeDataMIMEType || 
                connectionMIMEType.data != dataMIMEType
            let newMetadata: [CompositeMetadata]
            if shouldEncodeDataMIMEType {
                newMetadata = try metadata.encoded(dataMIMEType, using: dataMIMETypeEncoder)
            } else {
                newMetadata = metadata
            }
            return try encoder.encodedPayload(
                metadata: newMetadata, 
                data: try dataEncoder.encode(data, as: dataMIMEType), 
                mimeType: connectionMIMEType
            )
        }
    }
}

extension EncoderProtocol {
    func map<NewMetadata, NewData>(
        _ transform: @escaping (NewMetadata, NewData) throws -> (Metadata, Data)
    ) -> Encoders.Map<Self, NewMetadata, NewData> {
        .init(encoder: self, transform: transform)
    }
    func mapMetadata<NewMetadata>(
        _ transform: @escaping (NewMetadata) throws -> Metadata
    ) -> Encoders.MapMetadata<Self, NewMetadata> {
        .init(encoder: self, transform: transform)
    }
    func mapData<NewData>(
        _ transform: @escaping (NewData) throws -> Data
    ) -> Encoders.MapData<Self, NewData> {
        .init(encoder: self, transform: transform)
    }
    func encodeMetadata<MetadataEncoder>(
        using metadataEncoder: MetadataEncoder
    ) -> Encoders.MetadataEncoder<Self, MetadataEncoder> {
        .init(encoder: self, metadataEncoder: metadataEncoder)
    }
    func useCompositeMetadata(
        metadataEncoder: RootCompositeMetadataEncoder = .init()
    ) -> Encoders.RootCompositeMetadataEncoder<Self> where Metadata == Foundation.Data? {
        encodeMetadata(using: metadataEncoder)
    }
    /// adds the given metadata to the composition
    func encodeStaticMetadata<MetadataEncoder>(
        _ staticMetadata: MetadataEncoder.Metadata,
        using metadataEncoder: MetadataEncoder
    ) -> Encoders.StaticMetadataEncoder<Self, MetadataEncoder> {
        .init(encoder: self, metadataEncoder: metadataEncoder, staticMetadata: staticMetadata)
    }
    func encodeMetadata<MetadataEncoder>(
        @CompositeMetadataEncoderBuilder metadataEncoder: () -> MetadataEncoder
    ) -> Encoders.CompositeMetadataEncoder<Self, MetadataEncoder> {
            .init(encoder: self, metadataEncoder: metadataEncoder())
    }
    func encodeData<DataEncoder>(
        using dataEncoder: DataEncoder
    ) -> Encoders.DataEncoder<Self, DataEncoder> {
        .init(encoder: self, dataEncoder: dataEncoder)
    }
}

extension EncoderProtocol where Metadata == [CompositeMetadata], Data == Foundation.Data {
    func encodeData<Encoder>(
        alwaysEncodeDataMIMEType: Bool = false,
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init(),
        @MultiDataEncoderBuilder encoder: () -> Encoder
    ) -> Encoders.MultiDataEncoder<Self, Encoder> {
        .init(encoder: self, dataEncoder: encoder(), dataMIMETypeEncoder: dataMIMETypeEncoder, alwaysEncodeDataMIMEType: alwaysEncodeDataMIMEType)
    }
}

struct Encoder: EncoderProtocol {
    func encodedPayload(metadata: Data?, data: Data, mimeType: ConnectionMIMEType) throws -> Payload {
        .init(metadata: metadata, data: data)
    }
}

struct AnyEncoder<Metadata, Data>: EncoderProtocol {
    var _encoderBox: _AnyEncoderBase<Metadata, Data>
    init<Encoder>(
        _ encoder: Encoder
    ) where Encoder: EncoderProtocol, Encoder.Metadata == Metadata, Encoder.Data == Data {
        _encoderBox = _AnyEncoderBox(encoder: encoder)
    }
    mutating func encodedPayload(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload {
        if !isKnownUniquelyReferenced(&_encoderBox) {
            _encoderBox = _encoderBox.copy()
        }
        return try _encoderBox.encodedPayload(metadata: metadata, data: data, mimeType: mimeType)
    }
}

class _AnyEncoderBase<Metadata, Data>: EncoderProtocol {
    func encodedPayload(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
    func copy() -> _AnyEncoderBase<Metadata, Data> {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
}

final class _AnyEncoderBox<Encoder: EncoderProtocol>: _AnyEncoderBase<Encoder.Metadata, Encoder.Data> {
    var encoder: Encoder
    internal init(encoder: Encoder) {
        self.encoder = encoder
    }
    override func encodedPayload(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload {
        try encoder.encodedPayload(metadata: metadata, data: data, mimeType: mimeType)
    }
    override func copy() -> _AnyEncoderBase<Encoder.Metadata, Encoder.Data> {
        _AnyEncoderBox(encoder: encoder)
    }
}

extension AnyEncoder {
    func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { self }
}

extension EncoderProtocol {
    func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { .init(self) }
}

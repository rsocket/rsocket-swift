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
    mutating func encode(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload
}

public struct Encoder: EncoderProtocol {
    public func encode(metadata: Data?, data: Data, mimeType: ConnectionMIMEType) throws -> Payload {
        .init(metadata: metadata, data: data)
    }
}

public struct AnyEncoder<Metadata, Data>: EncoderProtocol {
    @usableFromInline
    internal var _encoderBox: _AnyEncoderBase<Metadata, Data>
    
    @inlinable
    internal init<Encoder>(
        _ encoder: Encoder
    ) where Encoder: EncoderProtocol, Encoder.Metadata == Metadata, Encoder.Data == Data {
        _encoderBox = _AnyEncoderBox(encoder: encoder)
    }
    
    @inlinable
    mutating public func encode(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload {
        if !isKnownUniquelyReferenced(&_encoderBox) {
            _encoderBox = _encoderBox.copy()
        }
        return try _encoderBox.encode(metadata: metadata, data: data, mimeType: mimeType)
    }
}

@usableFromInline
internal class _AnyEncoderBase<Metadata, Data>: EncoderProtocol {
    @usableFromInline
    func encode(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
    @usableFromInline
    func copy() -> _AnyEncoderBase<Metadata, Data> {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
}

@usableFromInline
final internal class _AnyEncoderBox<Encoder: EncoderProtocol>: _AnyEncoderBase<Encoder.Metadata, Encoder.Data> {
    @usableFromInline 
    internal var encoder: Encoder
    
    @usableFromInline 
    internal init(encoder: Encoder) {
        self.encoder = encoder
    }
    
    @usableFromInline 
    internal override func encode(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload {
        try encoder.encode(metadata: metadata, data: data, mimeType: mimeType)
    }
    
    @usableFromInline 
    internal override func copy() -> _AnyEncoderBase<Encoder.Metadata, Encoder.Data> {
        _AnyEncoderBox(encoder: encoder)
    }
}

extension AnyEncoder {
    @inlinable
    public func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { self }
}

extension EncoderProtocol {
    @inlinable
    public func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { .init(self) }
}

/// Namespace for types conforming to the ``EncoderProtocol`` protocol
public enum Encoders {}

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
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            let (metadata, data) = try transform(metadata, data)
            return try encoder.encode(metadata: metadata, data: data, mimeType: mimeType)
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


extension Encoders {
    public struct MapMetadata<Encoder: EncoderProtocol, Metadata>: EncoderProtocol {
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let transform: (Metadata) throws -> Encoder.Metadata
        
        @usableFromInline
        internal init(encoder: Encoder, transform: @escaping (Metadata) throws -> Encoder.Metadata) {
            self.encoder = encoder
            self.transform = transform
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Encoder.Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(metadata: try transform(metadata), data: data, mimeType: mimeType)
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func mapMetadata<NewMetadata>(
        _ transform: @escaping (NewMetadata) throws -> Metadata
    ) -> Encoders.MapMetadata<Self, NewMetadata> {
        .init(encoder: self, transform: transform)
    }
}


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


extension Encoders {
    public struct MetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata: MetadataEncodable,
    MetadataEncoder: RSocketCore.MetadataEncoder
    {
        public typealias Metadata = MetadataEncoder.Metadata
        public typealias Data = Encoder.Data
        
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let metadataEncoder: MetadataEncoder
        
        @usableFromInline
        internal init(encoder: Encoder, metadataEncoder: MetadataEncoder) {
            self.encoder = encoder
            self.metadataEncoder = metadataEncoder
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
                metadata: try Encoder.Metadata.encodeMetadata(metadata, using: metadataEncoder), 
                data: data, 
                mimeType: mimeType
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func encodeMetadata<MetadataEncoder>(
        using metadataEncoder: MetadataEncoder
    ) -> Encoders.MetadataEncoder<Self, MetadataEncoder> {
        .init(encoder: self, metadataEncoder: metadataEncoder)
    }
}



extension Encoders {
    public typealias RootCompositeMetadataEncoder<Encoder> = 
        MetadataEncoder<Encoder, RSocketCore.RootCompositeMetadataEncoder> where 
        Encoder: EncoderProtocol, 
        Encoder.Metadata == Foundation.Data?
}

extension EncoderProtocol {
    @inlinable
    public func useCompositeMetadata(
        metadataEncoder: RootCompositeMetadataEncoder = .init()
    ) -> Encoders.RootCompositeMetadataEncoder<Self> where Metadata == Foundation.Data? {
        encodeMetadata(using: metadataEncoder)
    }
}



extension Encoders {
    public struct StaticMetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata: MetadataEncodable,
    MetadataEncoder: RSocketCore.MetadataEncoder
    {
        public typealias Metadata = Encoder.Metadata.CombinableMetadata
        public typealias Data = Encoder.Data
        
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let metadataEncoder: MetadataEncoder
        
        @usableFromInline
        internal let staticMetadata: MetadataEncoder.Metadata
        
        @usableFromInline
        internal init(encoder: Encoder, metadataEncoder: MetadataEncoder, staticMetadata: MetadataEncoder.Metadata) {
            self.encoder = encoder
            self.metadataEncoder = metadataEncoder
            self.staticMetadata = staticMetadata
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
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
}

extension EncoderProtocol {
    /// adds the given metadata to the composition
    @inlinable
    public func encodeStaticMetadata<MetadataEncoder>(
        _ staticMetadata: MetadataEncoder.Metadata,
        using metadataEncoder: MetadataEncoder
    ) -> Encoders.StaticMetadataEncoder<Self, MetadataEncoder> {
        .init(encoder: self, metadataEncoder: metadataEncoder, staticMetadata: staticMetadata)
    }
}


extension Encoders {
    public struct CompositeMetadataEncoder<Encoder, MetadataEncoder>: EncoderProtocol where
    Encoder: EncoderProtocol,
    Encoder.Metadata == [CompositeMetadata],
    MetadataEncoder: RSocketCore.CompositeMetadataEncoder
    {
        public typealias Metadata = MetadataEncoder.Metadata
        public typealias Data = Encoder.Data
        
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let metadataEncoder: MetadataEncoder
        
        @usableFromInline
        internal init(encoder: Encoder, metadataEncoder: MetadataEncoder) {
            self.encoder = encoder
            self.metadataEncoder = metadataEncoder
        }
        
        @inlinable
        mutating public func encode(
            metadata: Metadata,
            data: Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
                metadata: metadataEncoder.encodeMetadata(metadata), 
                data: data, 
                mimeType: mimeType
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func encodeMetadata<MetadataEncoder>(
        @CompositeMetadataEncoderBuilder metadataEncoder: () -> MetadataEncoder
    ) -> Encoders.CompositeMetadataEncoder<Self, MetadataEncoder> {
            .init(encoder: self, metadataEncoder: metadataEncoder())
    }
}


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
            return try encoder.encode(
                metadata: newMetadata, 
                data: try dataEncoder.encode(data, as: dataMIMEType), 
                mimeType: connectionMIMEType
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

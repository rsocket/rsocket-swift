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
import NIO
import NIOFoundationCompat

// MARK: - Payload Decoder

// MARK: - Payload Encoder

protocol EncoderProtocol {
    associatedtype Metadata
    associatedtype Data
    mutating func encodedPayload(
        metadata: Metadata,
        data: Data,
        mimeType: ConnectionMIMEType
    ) throws -> Payload
}

enum Encoders {
    struct Map<Encoder: EncoderProtocol, Metadata, Data>: EncoderProtocol {
        var encoder: Encoder
        var transform: (Metadata, Data) throws -> (Encoder.Metadata, Encoder.Data)
        mutating func encodedPayload(
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
        var transform: (Metadata) throws -> Encoder.Metadata
        mutating func encodedPayload(
            metadata: Metadata,
            data: Encoder.Data,
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encodedPayload(metadata: try transform(metadata), data: data, mimeType: mimeType)
        }
    }
    struct MapData<Encoder: EncoderProtocol, Data>: EncoderProtocol {
        var encoder: Encoder
        var transform: (Data) throws -> Encoder.Data
        mutating func encodedPayload(
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
        typealias Metadata = MetadataEncoder.Metadata
        typealias Data = Encoder.Data
        var encoder: Encoder
        var metadataEncoder: MetadataEncoder
        mutating func encodedPayload(
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
        typealias Metadata = Encoder.Metadata.CombinableMetadata
        typealias Data = Encoder.Data
        var encoder: Encoder
        var metadataEncoder: MetadataEncoder
        var staticMetadata: MetadataEncoder.Metadata
        mutating func encodedPayload(
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
        typealias Metadata = MetadataEncoder.Metadata
        typealias Data = Encoder.Data
        var encoder: Encoder
        var metadataEncoder: MetadataEncoder
        mutating func encodedPayload(
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
        typealias Metadata = Encoder.Metadata
        typealias Data = DataEncoder.Data
        var encoder: Encoder
        var dataEncoder: DataEncoder
        mutating func encodedPayload(
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
        typealias Metadata = Encoder.Metadata
        typealias Data = (MIMEType, DataEncoder.Data)
        var encoder: Encoder
        var dataEncoder: DataEncoder
        var dataMIMETypeEncoder: DataMIMETypeEncoder
        var alwaysEncodeDataMIMEType: Bool
        mutating func encodedPayload(
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


// MARK: Coder

struct Coder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    var decoder: Decoder
    var encoder: Encoder
}

extension Coder {
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

// MARK: - Coder Extensions


extension Coder where Decoder.Metadata == Data?, Encoder.Metadata == Data? {
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

extension Coder {
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

// MARK: - Coder decode convenience methods

extension Coder {
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

extension Coder {
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


extension Coder {
    init() where
    Decoder == RSocketCore.Decoder,
    Encoder == RSocketCore.Encoder
    {
        self.init(decoder: .init(), encoder: .init())
    }
}

// MARK: - Erasable Metadata

protocol ErasableMetadata {
    static var erasedValue: Self { get }
}

extension Optional: ErasableMetadata {
    static var erasedValue: Optional<Wrapped> { nil }
}

extension Array: ErasableMetadata {
    static var erasedValue: Array<Element> { [] }
}

extension DecoderProtocol {
    func preserveMetadata() -> Decoders.Map<Self, Void, (Metadata, Data)> {
        map { ((), ($0, $1)) }
    }
    func eraseMetadata() -> Decoders.MapMetadata<Self, Void> where Metadata: ErasableMetadata {
        mapMetadata { _ in }
    }
}

extension EncoderProtocol {
    func preserveMetadata() -> Encoders.Map<Self, Void, (Metadata, Data)> {
        map { (metadata: Void, data: (Metadata, Data)) -> (Metadata, Data) in
            (data.0, data.1)
        }
    }
    func setMetadata(_ metadata: Metadata) -> Encoders.Map<Self, Void, Data> {
        map { (_, data: Data) -> (Metadata, Data) in
            (metadata, data)
        }
    }
    func eraseMetadata() -> Encoders.MapMetadata<Self, Void> where Metadata: ErasableMetadata {
        mapMetadata { _ in Metadata.erasedValue }
    }
}

// MARK: - Encoder Builder

@resultBuilder
enum EncoderBuilder: EncoderBuilderProtocol {
    static func buildBlock<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: EncoderProtocol {
        encoder
    }
}

protocol EncoderBuilderProtocol {}

extension EncoderBuilderProtocol {
    static func buildExpression<Encoder>(
        _ encoder: Encoder
    ) -> Encoders.Map<Encoder, Void, (Encoder.Metadata, Encoder.Data)> {
        encoder.preserveMetadata()
    }
    static func buildExpression<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: EncoderProtocol, Encoder.Metadata == Void {
        encoder
    }
    static func buildExpression<Encoder>(
        _ encoder: Encoder
    ) -> Encoders.MapMetadata<Encoder, Void> where Encoder: EncoderProtocol, Encoder.Metadata: ErasableMetadata {
        encoder.eraseMetadata()
    }
}

// MARK: - Decoder Builder

@resultBuilder
enum DecoderBuilder: DecoderBuilderProtocol {
    static func buildBlock<Decoder>(
        _ decoder: Decoder
    ) -> Decoder where Decoder: DecoderProtocol {
        decoder
    }
}

protocol DecoderBuilderProtocol {}

extension DecoderBuilderProtocol {
    static func buildExpression<Decoder>(
        _ decoder: Decoder
    ) -> Decoders.Map<Decoder, Void, (Decoder.Metadata, Decoder.Data)> {
        decoder.preserveMetadata()
    }
    static func buildExpression<Decoder>(
        _ decoder: Decoder
    ) -> Decoder where Decoder: DecoderProtocol, Decoder.Metadata == Void {
        decoder
    }
    static func buildExpression<Decoder>(
        _ decoder: Decoder
    ) -> Decoders.MapMetadata<Decoder, Void> where Decoder.Metadata: ErasableMetadata {
        decoder.eraseMetadata()
    }
}

// MARK: - Coder Builder

@resultBuilder
enum CoderBuilder: DecoderBuilderProtocol, EncoderBuilderProtocol {
    static func buildBlock<Decoder, Encoder>(
        _ decoder: Decoder,
        _ encoder: Encoder
    ) -> Coder<Decoder, Encoder> {
        .init(decoder: decoder, encoder: encoder)
    }
    static func buildBlock<Decoder, Encoder>(
        _ encoder: Encoder,
        _ decoder: Decoder
    ) -> Coder<Decoder, Encoder> {
        .init(decoder: decoder, encoder: encoder)
    }
    static func buildBlock<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoder, Encoder> {
        coder
    }
}

extension CoderBuilder {
    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoder, Encoder> where Decoder.Metadata == Void, Encoder.Metadata == Void {
        coder
    }

    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoders.MapMetadata<Decoder, Void>, Encoder> where Decoder.Metadata: ErasableMetadata, Encoder.Metadata == Void {
        coder.mapDecoder{ $0.eraseMetadata() }
    }

    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoder, Encoders.MapMetadata<Encoder, Void>> where Decoder.Metadata == Void, Encoder.Metadata: ErasableMetadata {
        coder.mapEncoder { $0.eraseMetadata() }
    }

    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoders.MapMetadata<Decoder, Void>, Encoders.MapMetadata<Encoder, Void>> where Decoder.Metadata: ErasableMetadata, Encoder.Metadata: ErasableMetadata {
        coder.mapEncoder { $0.eraseMetadata() }.mapDecoder{ $0.eraseMetadata() }
    }
}

// MARK: - Requester API

struct FireAndForget<Request> {
    let encoder: AnyEncoder<Void, Request>
}

extension FireAndForget {
    init<Encoder>(
        @EncoderBuilder _ makeEncoder: () -> Encoder
    ) where Encoder: EncoderProtocol, Encoder.Metadata == Void, Encoder.Data == Request {
        encoder = makeEncoder().eraseToAnyEncoder()
    }
}

struct RequestResponse<Request, Response> {
    let encoder: AnyEncoder<Void, Request>
    let decoder: AnyDecoder<Void, Response>
}

extension RequestResponse {
    init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
Encoder.Metadata == Void, Encoder.Data == Request,
Decoder.Metadata == Void, Decoder.Data == Response {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

struct RequestStream<Request, Response> {
    let encoder: AnyEncoder<Void, Request>
    let decoder: AnyDecoder<Void, Response>
}

extension RequestStream {
    init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
Encoder.Metadata == Void, Encoder.Data == Request,
Decoder.Metadata == Void, Decoder.Data == Response {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

struct RequestChannel<Request, Response> {
    let encoder: AnyEncoder<Void, Request>
    let decoder: AnyDecoder<Void, Response>
}

extension RequestChannel {
    init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
Encoder.Metadata == Void, Encoder.Data == Request,
Decoder.Metadata == Void, Decoder.Data == Response {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

// MARK: - Requester Example

struct Metrics: Codable {
    var os: String
}

struct Stock: Codable {
    var isin: ISIN
}
struct ISIN: Codable {
    var isin: String
}
struct Price: Codable {
    var price: Double
}

enum Requests {
    static let metrics1 = FireAndForget<Metrics> {
        Encoder()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: Metrics.self))
    }
    static let metrics2 = FireAndForget<Metrics> {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: Metrics.self))
    }
    static let metrics3 = FireAndForget<([CompositeMetadata], Metrics)> {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: Metrics.self))
            .preserveMetadata()
    }
    static let priceRequest1 = RequestResponse<String, Double> {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeStaticMetadata([.json], using: .acceptableDataMIMEType)
            .encodeData(using: JSONDataEncoder(type: ISIN.self))
            .mapData(ISIN.init(isin:))
        Decoder()
            .useCompositeMetadata()
            .decodeData(using: JSONDataDecoder(type: Price.self).map(\.price))
    }
    static let priceRequest2 = RequestResponse<String, Double> {
        Coder()
            .useCompositeMetadata()
            .decodeData {
                JSONDataDecoder(type: Price.self).map(\.price)
            }
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: ISIN.self).map(ISIN.init(isin:)))
    }
    static let priceRequest3 = RequestResponse<(MIMEType, String), Double> {
        Coder()
            .useCompositeMetadata()
            .decodeData {
                JSONDataDecoder(type: Price.self)
                    .map(\.price)
            }
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeData {
                JSONDataEncoder(type: ISIN.self).map(ISIN.init(isin:))
            }
    }
    static let priceStream1 = RequestStream<ISIN, Price> {
        Coder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: ISIN.self))
            .decodeData {
                JSONDataDecoder(type: Price.self)
                JSONDataDecoder(type: Price.self)
            }
    }
}

func test() {
    _ = Encoder()
        .encodeMetadata(using: RoutingEncoder())
        .setMetadata(["stock.isin"])
    
    _ = Decoder()
        .useCompositeMetadata()
        .decodeMetadata {
            RoutingDecoder()
            DataMIMETypeDecoder()
        }
        .decodeData(using: JSONDataDecoder(type: Metrics.self))

    _ = Encoder()
        .useCompositeMetadata()
        .encodeMetadata {
            RoutingEncoder()
            DataMIMETypeEncoder()
        }
        .encodeData(using: JSONDataEncoder(type: Metrics.self))

    _ = Coder()
        .useCompositeMetadata()
        .decodeData {
            JSONDataDecoder(type: Metrics.self)
        }
        .encodeData {
            JSONDataEncoder(type: Metrics.self)
        }
        .decodeMetadata {
            RoutingDecoder()
            AcceptableDataMIMETypeDecoder()
            DataMIMETypeDecoder()
        }
        .encodeMetadata {
            RoutingEncoder()
            DataMIMETypeEncoder()
        }
        

    _ = RequestStream {
        Decoder()
            .useCompositeMetadata()
            .decodeMetadata {
                RoutingDecoder()
            }
        Encoder()
            .useCompositeMetadata()
            .encodeMetadata {
                RoutingEncoder()
                DataMIMETypeEncoder()
            }
    }
}


// MARK: - Responder Experiments

struct Router {
    var routes: [Route]
}

struct Route {
    var path: [String]
    var handler: [RouteHandler]
}

protocol RouteHandler {

}

protocol RequestResponseHandler {
    associatedtype Request
    associatedtype Response
    func handleRequest(_ request: Request) async throws -> Response
}

struct RequestResponseResponderDescription<
    Decoder: DecoderProtocol,
    Encoder: EncoderProtocol,
    Handler: RequestResponseHandler
>: RouteHandler
{
    var decoder: Decoder
    var encoder: Encoder
    var handler: Handler
}

struct AsyncAwaitRequestResponseHandler<Request, Response>: RequestResponseHandler {
    var handler: (Request) async throws -> Response
    func handleRequest(_ request: Request) async throws -> Response {
        try await handler(request)
    }
}


struct FireAndForgetResponder<Decoder> where Decoder: DecoderProtocol {
    @DecoderBuilder let decoder: Decoder
}
struct RequestResponseResponder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    @CoderBuilder let coder: Coder<Decoder, Encoder>
}

struct RequestStreamResponder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    @CoderBuilder let coder: Coder<Decoder, Encoder>
}

struct RequestChannelResponder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    @CoderBuilder let coder: Coder<Decoder, Encoder>
}

extension RequestResponseResponder {
    func handler(
        _ handler: @escaping (Decoder.Data) async throws -> Encoder.Data
    ) -> RequestResponseResponderDescription<Decoder, Encoder, AsyncAwaitRequestResponseHandler<Decoder.Data, Encoder.Data>> {
            .init(decoder: coder.decoder, encoder: coder.encoder, handler: .init(handler: handler))
    }
}

@available(macOS 12.0, *)
func exampleRouter() -> Router {

    let responder = RequestResponseResponder{
        Coder()
            .useCompositeMetadata()
            .decodeData {
                JSONDataDecoder(type: Metrics.self)
                JSONDataDecoder(type: Metrics.self)
            }
            .encodeData {
                JSONDataEncoder(type: Metrics.self)
            }
    }.handler { request in
        (.json, request)
    }

    let routes = [Route(path: ["stock.isin"], handler: [responder])]
    return Router(routes: routes)
    
//    Router {
//        Route(path: "stock.isin") {
//            RequestResponseResponder {
//                Coder()
//                    .useCompositeMetadata()
//                    .decodeData {
//                        JSONDataDecoder(type: Metrics.self)
//                        JSONDataDecoder(type: Metrics.self)
//                    }
//                    .encodeData {
//                        JSONDataEncoder(type: Metrics.self)
//                    }
//            }.handler { request in
//                (.json, request)
//            }
//            
//            RequestStreamResponder{
//                Coder()
//                    .useCompositeMetadata()
//                    .decodeData {
//                        JSONDataDecoder(type: Metrics.self)
//                        JSONDataDecoder(type: Metrics.self)
//                    }
//                    .encodeData {
//                        JSONDataEncoder(type: Metrics.self)
//                    }
//            }.handler { request in
//                (.json, request)
//            }
//        }
//    }
}


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

protocol DecoderProtocol {
    associatedtype Metadata
    associatedtype Data
    func decodedPayload(_ payload: Payload) throws -> (Metadata, Data)
}


/// Namespace
enum Decoders {}

extension Decoders {
    struct Map<Decoder: DecoderProtocol, Metadata, Data>: DecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Metadata, Decoder.Data) throws -> (Metadata, Data)
        func decodedPayload(_ payload: Payload) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload)
            return try transform(metadata, data)
        }
    }
    struct MapMetadata<Decoder: DecoderProtocol, Metadata>: DecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Metadata) throws -> Metadata
        func decodedPayload(_ payload: Payload) throws -> (Metadata, Decoder.Data) {
            let (metadata, data) = try decoder.decodedPayload(payload)
            return (try transform(metadata), data)
        }
    }
    struct MapData<Decoder: DecoderProtocol, Data>: DecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Data) throws -> Data
        func decodedPayload(_ payload: Payload) throws -> (Decoder.Metadata, Data) {
            let (metadata, data) = try decoder.decodedPayload(payload)
            return (metadata, try transform(data))
        }
    }
}

extension DecoderProtocol {
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
}

struct AnyDecoder<Metadata, Data>: DecoderProtocol {
    var _decodedPayload: (Payload) throws -> (Metadata, Data)
    init<Decoder>(
        _ decoder: Decoder
    ) where Decoder: DecoderProtocol, Decoder.Metadata == Metadata, Decoder.Data == Data {
        _decodedPayload = decoder.decodedPayload(_:)
    }
    func decodedPayload(_ payload: Payload) throws -> (Metadata, Data) {
        try _decodedPayload(payload)
    }
}

extension DecoderProtocol {
    func eraseToAnyDecoder() -> AnyDecoder<Metadata, Data> {
        .init(self)
    }
}

struct Decoder: DecoderProtocol {
    init() {}
    func decodedPayload(_ payload: Payload) throws -> (Data?, Data) {
        (payload.metadata, payload.data)
    }
}

// MARK: - Payload Encoder

protocol EncoderProtocol {
    associatedtype Metadata
    associatedtype Data
    func encodedPayload(metadata: Metadata, data: Data) throws -> Payload
}

enum Encoders {
    struct Map<Encoder: EncoderProtocol, Metadata, Data>: EncoderProtocol {
        var encoder: Encoder
        var transform: (Metadata, Data) throws -> (Encoder.Metadata, Encoder.Data)
        func encodedPayload(metadata: Metadata, data: Data) throws -> Payload {
            let (metadata, data) = try transform(metadata, data)
            return try encoder.encodedPayload(metadata: metadata, data: data)
        }
    }
    struct MapMetadata<Encoder: EncoderProtocol, Metadata>: EncoderProtocol {
        var encoder: Encoder
        var transform: (Metadata) throws -> Encoder.Metadata
        func encodedPayload(metadata: Metadata, data: Encoder.Data) throws -> Payload {
            try encoder.encodedPayload(metadata: try transform(metadata), data: data)
        }
    }
    struct MapData<Encoder: EncoderProtocol, Data>: EncoderProtocol {
        var encoder: Encoder
        var transform: (Data) throws -> Encoder.Data
        func encodedPayload(metadata: Encoder.Metadata, data: Data) throws -> Payload {
            try encoder.encodedPayload(metadata: metadata, data: try transform(data))
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
}

struct AnyEncoder<Metadata, Data>: EncoderProtocol {
    var _encodedPayload: (Metadata, Data) throws -> Payload
    init<Encoder>(
        _ encoder: Encoder
    ) where Encoder: EncoderProtocol, Encoder.Metadata == Metadata, Encoder.Data == Data {
        _encodedPayload = encoder.encodedPayload(metadata:data:)
    }
    func encodedPayload(metadata: Metadata, data: Data) throws -> Payload {
        try _encodedPayload(metadata, data)
    }
}

extension AnyEncoder {
    func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { self }
}

extension EncoderProtocol {
    func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { .init(self) }
}

// MARK: Decoder Extensions

extension DecoderProtocol where Metadata == Foundation.Data? {
    func decodeMetadata<Decoder>(
        using decoder: Decoder
    ) -> Decoders.MapMetadata<Self, Decoder.Metadata?> where Decoder: MetadataDecoder {
        mapMetadata { data in
            try data.map { try decoder.decode(from: $0) }
        }
    }
}

extension DecoderProtocol where Data == Foundation.Data {
    /// unconditionally decodes data with the given `decoder`
    func decodeData<Decoder>(
        using decoder: Decoder
    ) -> Decoders.MapData<Self, Decoder.Data> where Decoder: DataDecoderProtocol {
        mapData(decoder.decode(from:))
    }
}

extension DecoderProtocol where Metadata == Foundation.Data? {
    func useCompositeMetadata(
        decoder: RootCompositeMetadataDecoder = .init()
    ) -> Decoders.MapMetadata<Decoders.MapMetadata<Self, RootCompositeMetadataDecoder.Metadata?>, RootCompositeMetadataDecoder.Metadata> {
        decodeMetadata(using: decoder).mapMetadata{ $0 ?? [] }
    }
}

// MARK: Encoder Extensions

extension EncoderProtocol where Metadata == Foundation.Data? {
    func encodeMetadata<Encoder>(
        using encoder: Encoder
    ) -> Encoders.MapMetadata<Self, Encoder.Metadata> where Encoder: MetadataEncoder {
        mapMetadata { metadata in
            try encoder.encode(metadata)
        }
    }
}

extension EncoderProtocol where Metadata == Foundation.Data? {
    func useCompositeMetadata(
        encoder: RootCompositeMetadataEncoder = .init()
    ) -> Encoders.MapMetadata<Self, RootCompositeMetadataEncoder.Metadata> {
        encodeMetadata(using: encoder)
    }
}

extension EncoderProtocol where Metadata == [CompositeMetadata] {
    /// adds the given metadata to the composition
    func encodeStaticMetadata<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) -> Encoders.MapMetadata<Self, [CompositeMetadata]> where Encoder: MetadataEncoder {
        mapMetadata { compositeMetadata in
            try compositeMetadata.encoded(metadata, using: encoder)
        }
    }
}

extension EncoderProtocol where Metadata == [CompositeMetadata] {
    func encodeMetadata<Encoder>(
        using encoder: Encoder
    ) -> Encoders.MapMetadata<Self, Encoder.Metadata> where Encoder: MetadataEncoder {
        mapMetadata { metadata in
            [try CompositeMetadata.encoded(metadata, using: encoder)]
        }
    }
}

extension EncoderProtocol where Data == Foundation.Data {
    func encodeData<Encoder>(
        using encoder: Encoder
    ) -> Encoders.MapData<Self, Encoder.Data> where Encoder: DataEncoderProtocol {
        mapData(encoder.encode)
    }
}

extension EncoderProtocol where Metadata == [CompositeMetadata], Data == Foundation.Data {
    func encodeData<Encoder>(
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init(),
        @MultiDataEncoderBuilder encoder: () -> Encoder
    ) -> Encoders.Map<Self, Metadata, (MIMEType, Encoder.Data)> where Encoder: MultiDataEncoderProtocol {
        let encoder = encoder()
        return map { metadata, data in
            let (mimeType, data) = data

            return (
                try metadata.encoded(mimeType, using: dataMIMETypeEncoder),
                try encoder.encode(data, as: mimeType)
            )
        }
    }
}

struct Encoder: EncoderProtocol {
    func encodedPayload(metadata: Data?, data: Data) throws -> Payload {
        .init(metadata: metadata, data: data)
    }
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
        decoder: RootCompositeMetadataDecoder = .init(),
        encoder: RootCompositeMetadataEncoder = .init()
    ) -> Coder<
        Decoders.MapMetadata<Decoders.MapMetadata<Decoder, RootCompositeMetadataDecoder.Metadata?>, RootCompositeMetadataDecoder.Metadata>,
        Encoders.MapMetadata<Encoder, RootCompositeMetadataEncoder.Metadata>
    > {
        mapDecoder { $0.useCompositeMetadata(decoder: decoder) }
        .mapEncoder { $0.useCompositeMetadata(encoder: encoder) }
    }
}

extension Coder where Decoder.Data == Foundation.Data, Decoder.Metadata == [CompositeMetadata], Encoder.Metadata == [CompositeMetadata] {
    /// Decodes data using one of the given `decoder`s, depending on the MIME Type of the Data.
    ///
    /// In addition, this methods encodes all MIME Types of all `decoder`s using the given `acceptableDataMIMETypeEncoder`.
    /// This makes it possible for a requester to support multiple response data MIME Types at the same time and let the responder choose the best one.
    func decodeData<DataDecoder>(
        acceptableDataMIMETypeEncoder: AcceptableDataMIMETypeEncoder = .init(),
        dataMIMETypeDecoder: DataMIMETypeDecoder = .init(),
        @MultiDataDecoderBuilder decoder: () -> DataDecoder
    ) -> Coder<Decoders.Map<Decoder, [CompositeMetadata], DataDecoder.Data>, Encoders.MapMetadata<Encoder, [CompositeMetadata]>> where DataDecoder: MultiDataDecoderProtocol {
        let decoder = decoder()
        let supportedEncodings = decoder.supportedMIMETypes
        return mapEncoder{
            $0.encodeStaticMetadata(supportedEncodings, using: acceptableDataMIMETypeEncoder)
        }.mapDecoder{
            $0.map { (metadata, data) in
                guard let dataEncoding = try metadata.decodeFirstIfPresent(using: dataMIMETypeDecoder) else {
                    throw Error.invalid(message: "Data MIME Type not found in metadata")
                }
                let value = try decoder.decodeMIMEType(dataEncoding, from: data)
                return (metadata, value)
            }
        }
    }
}

// MARK: - Coder decode convenience methods

extension Coder where Decoder.Metadata == Foundation.Data? {
    func decodeMetadata<MetadataDecoder>(
        using decoder: MetadataDecoder
    ) -> Coder<Decoders.MapMetadata<Decoder, MetadataDecoder.Metadata?>, Encoder> where MetadataDecoder: RSocketCore.MetadataDecoder {
        mapDecoder { $0.decodeMetadata(using: decoder) }
    }
}

extension Coder where Decoder.Data == Foundation.Data {
    /// unconditionally decodes data with the given `decoder`
    func decodeData<DataDecoder>(
        using decoder: DataDecoder
    ) -> Coder<Decoders.MapData<Decoder, DataDecoder.Data>, Encoder> where DataDecoder: DataDecoderProtocol {
        mapDecoder { $0.decodeData(using: decoder) }
    }
}

// MARK: - Coder encode convenience methods

extension Coder where Encoder.Metadata == Foundation.Data? {
    func encodeMetadata<MetadataEncoder>(
        using encoder: MetadataEncoder
    ) -> Coder<Decoder, Encoders.MapMetadata<Encoder, MetadataEncoder.Metadata>> where MetadataEncoder: RSocketCore.MetadataEncoder {
        mapEncoder { $0.encodeMetadata(using: encoder) }
    }
}

extension Coder where Encoder.Metadata == [CompositeMetadata] {
    func encodeStaticMetadata<MetadataEncoder>(
        _ metadata: MetadataEncoder.Metadata,
        using encoder: MetadataEncoder
    ) -> Coder<Decoder, Encoders.MapMetadata<Encoder, Encoder.Metadata>> where MetadataEncoder: RSocketCore.MetadataEncoder {
        mapEncoder { $0.encodeStaticMetadata(metadata, using: encoder) }
    }
}

extension Coder where Encoder.Data == Foundation.Data {
    func encodeData<DataEncoder>(
        using encoder: DataEncoder
    ) -> Coder<Decoder, Encoders.MapData<Encoder, DataEncoder.Data>> where DataEncoder: DataEncoderProtocol {
        mapEncoder { $0.encodeData(using: encoder) }
    }
}

extension Coder where Encoder.Metadata == [CompositeMetadata], Encoder.Data == Foundation.Data {
    func encodeData<DataEncoder>(
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init(),
        @MultiDataEncoderBuilder encoder: () -> DataEncoder
    ) -> Coder<Decoder, Encoders.Map<Encoder, Encoder.Metadata, (MIMEType, DataEncoder.Data)>> where DataEncoder: MultiDataEncoderProtocol {
        mapEncoder { $0.encodeData(dataMIMETypeEncoder: dataMIMETypeEncoder, encoder: encoder) }
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

struct Metrics: Encodable {
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
    static let metrics1: FireAndForget<Metrics> = .init {
        Encoder()
            .encodeMetadata(using: .routing)
            .setMetadata(["metrics"])
            .encodeData(using: JSONDataEncoder<Metrics>())
    }
    static let metrics2: FireAndForget<Metrics> = .init {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder<Metrics>())
    }
    static let metrics3: FireAndForget<([CompositeMetadata], Metrics)> = .init {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder<Metrics>())
            .preserveMetadata()
    }
    static let priceRequest1: RequestResponse<String, Double> = .init{
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeStaticMetadata([.json], using: .acceptableDataMIMEType)
            .encodeData(using: JSONDataEncoder<ISIN>())
            .mapData(ISIN.init(isin:))
        Decoder()
            .useCompositeMetadata()
            .decodeData(using: JSONDataDecoder<Price>().map(\.price))
    }
    static let priceRequest2: RequestResponse<String, Double> = .init{
        Coder()
            .useCompositeMetadata()
            .decodeData {
                JSONDataDecoder<Price>()
            }
            .mapEncoder {
                $0.encodeStaticMetadata(["price"], using: .routing)
                    .encodeData(using: JSONDataEncoder<ISIN>())
                    .mapData(ISIN.init(isin:))
                    .setMetadata([])
            }
            .mapDecoder {
                $0.mapData(\.price).eraseMetadata()
            }
    }
    static let priceRequest3: RequestResponse<String, Double> = .init{
        Coder()
            .useCompositeMetadata()
            .decodeData {
                JSONDataDecoder<Price>()
            }
            .mapEncoder {
                $0.encodeStaticMetadata(["price"], using: .routing)
                    .encodeData(using: JSONDataEncoder<ISIN>())
                    .mapData(ISIN.init(isin:))
                    .setMetadata([])
            }
            .mapDecoder {
                $0.mapData(\.price)
            }
    }
    static let priceRequest4: RequestResponse<String, Double> = .init{
        Coder()
            .useCompositeMetadata()
            .decodeData {
                JSONDataDecoder<Price>()
            }
            .mapEncoder {
                $0.encodeStaticMetadata(["price"], using: .routing)
                    .encodeData(using: JSONDataEncoder<ISIN>())
                    .mapData(ISIN.init(isin:))
            }
            .mapDecoder {
                $0.mapData(\.price).eraseMetadata()
            }
    }
    static let priceRequest5: RequestResponse<(MIMEType, String), Double> = .init {
        Coder()
            .useCompositeMetadata()
            .decodeData {
                JSONDataDecoder<Price>()
            }
            .mapEncoder {
                $0.encodeStaticMetadata(["price"], using: .routing)
                    .encodeData {
                        JSONDataEncoder<ISIN>()
                            .map(ISIN.init(isin:))
                    }
            }
            .mapDecoder {
                $0.mapData(\.price)
            }
    }
    static let priceStream1: RequestStream<ISIN, Price> = .init{
        Coder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeData(using: JSONDataEncoder<ISIN>())
            .decodeData {
                JSONDataDecoder<Price>()
            }
    }
}

func test() {
    let decoder = Decoder()
        .useCompositeMetadata()
        .decodeMetadata {
            RoutingDecoder()
            DataMIMETypeDecoder()
        }

    let encoder = Encoder()
        .useCompositeMetadata()
        .encodeMetadata {
            RoutingEncoder()
            DataMIMETypeEncoder()
        }
    let request = RequestStream {
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
    }.handler { request in
        request
    }

    let routes = [Route(path: ["stock.isin"], handler: [responder])]
    return Router(routes: routes)
}


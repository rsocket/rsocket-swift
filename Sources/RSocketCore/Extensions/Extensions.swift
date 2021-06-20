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
    associatedtype Request = Payload
    associatedtype Metadata
    associatedtype Data
    func decodeRequest(_ request: Request) throws -> (Metadata, Data)
}


/// Namespace
enum Decoders {}

extension Decoders {
    struct Start<Request, Metadata, Data>: DecoderProtocol {

        var make: (Request) -> (Metadata, Data)
        func decodeRequest(_ request: Request) throws -> (Metadata, Data) {
            make(request)
        }
    }
    struct MapRequest<Decoder: DecoderProtocol, Request>: DecoderProtocol {
        var decoder: Decoder
        var transform: (Request) throws -> (Decoder.Request)
        func decodeRequest(_ request: Request) throws -> (Decoder.Metadata, Decoder.Data) {
            let request = try transform(request)
            return try decoder.decodeRequest(request)
        }
    }
    struct Map<Decoder: DecoderProtocol, Metadata, Data>: DecoderProtocol {
        typealias Request = Decoder.Request
        var decoder: Decoder
        var transform: (Decoder.Metadata, Decoder.Data) throws -> (Metadata, Data)
        func decodeRequest(_ request: Request) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodeRequest(request)
            return try transform(metadata, data)
        }
    }
    struct MapMetadata<Decoder: DecoderProtocol, Metadata>: DecoderProtocol {
        typealias Request = Decoder.Request
        var decoder: Decoder
        var transform: (Decoder.Metadata) throws -> Metadata
        func decodeRequest(_ request: Request) throws -> (Metadata, Decoder.Data) {
            let (metadata, data) = try decoder.decodeRequest(request)
            return (try transform(metadata), data)
        }
    }
    struct MapData<Decoder: DecoderProtocol, Data>: DecoderProtocol {
        typealias Request = Decoder.Request
        var decoder: Decoder
        var transform: (Decoder.Data) throws -> Data
        func decodeRequest(_ request: Request) throws -> (Decoder.Metadata, Data) {
            let (metadata, data) = try decoder.decodeRequest(request)
            return (metadata, try transform(data))
        }
    }
}

extension DecoderProtocol {
    func mapRequest<NewRequest>(
        _ transform: @escaping (NewRequest) throws -> Request
    ) -> Decoders.MapRequest<Self, NewRequest> {
        .init(decoder: self, transform: transform)
    }
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

struct AnyDecoder<Request, Metadata, Data>: DecoderProtocol {
    var _decodeRequest: (Request) throws -> (Metadata, Data)
    init<Decoder>(
        _ decoder: Decoder
    ) where Decoder: DecoderProtocol, Decoder.Request == Request, Decoder.Metadata == Metadata, Decoder.Data == Data {
        _decodeRequest = decoder.decodeRequest(_:)
    }
    func decodeRequest(_ request: Request) throws -> (Metadata, Data) {
        try _decodeRequest(request)
    }
}

extension DecoderProtocol {
    func eraseToAnyDecoder() -> AnyDecoder<Request, Metadata, Data> {
        .init(self)
    }
}

// MARK: - Payload Encoder

protocol EncoderProtocol {
    associatedtype Response = Payload
    associatedtype Metadata
    associatedtype Data
    func encodeResponse(metadata: Metadata, data: Data) throws -> Response
}

enum Encoders {
    struct Start<Response, Metadata, Data>: EncoderProtocol {
        var make: (Metadata, Data) -> Response
        func encodeResponse(metadata: Metadata, data: Data) throws -> Response {
            make(metadata, data)
        }
    }
    struct MapResponse<Encoder: EncoderProtocol, Response>: EncoderProtocol {
        var encoder: Encoder
        var transform: (Encoder.Response) throws -> (Response)
        func encodeResponse(metadata: Encoder.Metadata, data: Encoder.Data) throws -> Response {
            try transform(try encoder.encodeResponse(metadata: metadata, data: data))
        }
    }
    struct Map<Encoder: EncoderProtocol, Metadata, Data>: EncoderProtocol {
        typealias Response = Encoder.Response
        var encoder: Encoder
        var transform: (Metadata, Data) throws -> (Encoder.Metadata, Encoder.Data)
        func encodeResponse(metadata: Metadata, data: Data) throws -> Response {
            let (metadata, data) = try transform(metadata, data)
            return try encoder.encodeResponse(metadata: metadata, data: data)
        }
    }
    struct MapMetadata<Encoder: EncoderProtocol, Metadata>: EncoderProtocol {
        typealias Response = Encoder.Response
        var encoder: Encoder
        var transform: (Metadata) throws -> Encoder.Metadata
        func encodeResponse(metadata: Metadata, data: Encoder.Data) throws -> Response {
            try encoder.encodeResponse(metadata: try transform(metadata), data: data)
        }
    }
    struct MapData<Encoder: EncoderProtocol, Data>: EncoderProtocol {
        typealias Response = Encoder.Response
        var encoder: Encoder
        var transform: (Data) throws -> Encoder.Data
        func encodeResponse(metadata: Encoder.Metadata, data: Data) throws -> Response {
            try encoder.encodeResponse(metadata: metadata, data: try transform(data))
        }
    }
}

extension EncoderProtocol {
    func mapResponse<NewResponse>(
        _ transform: @escaping (Response) throws -> NewResponse
    ) -> Encoders.MapResponse<Self, NewResponse> {
        .init(encoder: self, transform: transform)
    }
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

struct AnyEncoder<Response, Metadata, Data>: EncoderProtocol {
    var _encodeRequest: (Metadata, Data) throws -> Response
    init<Encoder>(
        _ encoder: Encoder
    ) where Encoder: EncoderProtocol, Encoder.Response == Response, Encoder.Metadata == Metadata, Encoder.Data == Data {
        _encodeRequest = encoder.encodeResponse(metadata:data:)
    }
    func encodeResponse(metadata: Metadata, data: Data) throws -> Response {
        try _encodeRequest(metadata, data)
    }
}

extension AnyEncoder {
    func eraseToAnyEncoder() -> AnyEncoder<Response, Metadata, Data> { self }
}

extension EncoderProtocol {
    func eraseToAnyEncoder() -> AnyEncoder<Response, Metadata, Data> { .init(self) }
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
    func decodeData<NewData>(
        using decoder: DataDecoder<NewData>
    ) -> Decoders.MapData<Self, NewData> {
        mapData(decoder.decode(from:))
    }
}

extension DecoderProtocol where Metadata == Foundation.Data? {
    func useCompositeMetadata(
        decoder: CompositeMetadataDecoder = .init()
    ) -> Decoders.MapMetadata<Decoders.MapMetadata<Self, CompositeMetadataDecoder.Metadata?>, CompositeMetadataDecoder.Metadata> {
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
        encoder: CompositeMetadataEncoder = .init()
    ) -> Encoders.MapMetadata<Self, CompositeMetadataEncoder.Metadata> {
        encodeMetadata(using: encoder)
    }
}

extension EncoderProtocol where Metadata == [CompositeMetadata] {
    /// adds the given metadata to the composition
    func encodeMetadata<Encoder>(
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
    func encodeData<NewData>(
        using encoder: DataEncoder<NewData>
    ) -> Encoders.MapData<Self, NewData> {
        mapData(encoder.encode)
    }
}

extension EncoderProtocol where Metadata == [CompositeMetadata], Data == Foundation.Data {
    func encodeData<NewData>(
        using encoder: DataEncoder<NewData>,
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init()
    ) -> Encoders.MapData<Encoders.MapMetadata<Self, [CompositeMetadata]>, NewData> {
        encodeMetadata(encoder.mimeType, using: dataMIMETypeEncoder)
            .encodeData(using: encoder)
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
        decoder: CompositeMetadataDecoder = .init(),
        encoder: CompositeMetadataEncoder = .init()
    ) -> Coder<
        Decoders.MapMetadata<Decoders.MapMetadata<Decoder, CompositeMetadataDecoder.Metadata?>, CompositeMetadataDecoder.Metadata>,
        Encoders.MapMetadata<Encoder, CompositeMetadataEncoder.Metadata>
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
    func decodeData<NewOutputValue>(
        using decoder: [DataDecoder<NewOutputValue>],
        acceptableDataMIMETypeEncoder: AcceptableDataMIMETypeEncoder = .init(),
        dataMIMETypeDecoder: DataMIMETypeDecoder = .init()
    ) -> Coder<Decoders.Map<Decoder, [CompositeMetadata], NewOutputValue>, Encoders.MapMetadata<Encoder, [CompositeMetadata]>> {
        let supportedEncodings = decoder.map(\.mimeType)
        return mapEncoder{
            $0.encodeMetadata(supportedEncodings, using: acceptableDataMIMETypeEncoder)
        }.mapDecoder{
            $0.map { (metadata, data) -> (Decoder.Metadata, NewOutputValue) in
                guard let dataEncoding = try metadata.decodeFirst(using: dataMIMETypeDecoder) else {
                    throw Error.invalid(message: "Data MIME Type not found in metadata")
                }
                guard let decoder = decoder.first(where: { $0.mimeType == dataEncoding }) else {
                    throw Error.invalid(message: "\(dataEncoding) is not supported, should be \(supportedEncodings)")
                }
                let value = try decoder.decode(from: data)
                return (metadata, value)
            }
        }
    }
}

// MARK: - Coder Encoder Decoder extensions



extension Coder {
    init() where
    Decoder == Decoders.Start<Payload, Data?, Data>,
    Encoder == Encoders.Start<Payload, Data?, Data>
    {
        self.init(decoder: RSocketCore.Decoder(), encoder: RSocketCore.Encoder())
    }
}



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

func Decoder() -> Decoders.Start<Payload, Data?, Data> {
    Decoders.Start { (payload: Payload) in (payload.metadata, payload.data) }
}

func Encoder() -> Encoders.Start<Payload, Data?, Data> {
    Encoders.Start { (metadata, data) in Payload(metadata: metadata, data: data) }
}

struct AsyncAwaitRequestResponseHandler<Request, Response>: RequestResponseHandler {
    var handler: (Request) async throws -> Response
    func handleRequest(_ request: Request) async throws -> Response {
        try await handler(request)
    }
}


struct FireAndForgetResponder<Decoder> where Decoder: DecoderProtocol {
    let decoder: Decoder
}
struct RequestResponseResponder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    let coder: Coder<Decoder, Encoder>
}

struct RequestStreamResponder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    let coder: Coder<Decoder, Encoder>
}

struct RequestChannelResponder<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    let coder: Coder<Decoder, Encoder>
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
    let responder = RequestResponseResponder(
        coder: Coder()
    ).handler { request in
        request
    }

    let routes = [Route(path: ["stock.isin"], handler: [responder])]
    return Router(routes: routes)
}

extension DecoderProtocol {
    func preserveMetadata() -> Decoders.Map<Self, Void, (Metadata, Data)> {
        map { ((), ($0, $1)) }
    }
    func eraseMetadata() -> Decoders.Map<Self, Void, Data> {
        map { _, data in ((), data) }
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
}

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
    ) -> Encoders.Map<Encoder, Void, Encoder.Data> where Encoder: EncoderProtocol, Encoder.Metadata == Data? {
        encoder.setMetadata(nil)
    }
    static func buildExpression<Encoder>(
        _ encoder: Encoder
    ) -> Encoders.Map<Encoder, Void, Encoder.Data> where Encoder: EncoderProtocol, Encoder.Metadata == [CompositeMetadata] {
        encoder.setMetadata([])
    }
}

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
    ) -> Decoders.Map<Decoder, Void, Decoder.Data> where Decoder.Metadata == Data? {
        decoder.eraseMetadata()
    }
    static func buildExpression<Decoder>(
        _ decoder: Decoder
    ) -> Decoders.Map<Decoder, Void, Decoder.Data> where Decoder.Metadata == [CompositeMetadata] {
        decoder.eraseMetadata()
    }
}

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
    ) -> Coder<Decoders.Map<Decoder, Void, Decoder.Data>, Encoder> where Decoder.Metadata == Data?, Encoder.Metadata == Void {
        coder.mapDecoder{ $0.eraseMetadata() }
    }
    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoders.Map<Decoder, Void, Decoder.Data>, Encoder> where Decoder.Metadata == [CompositeMetadata], Encoder.Metadata == Void {
        coder.mapDecoder{ $0.eraseMetadata() }
    }

    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoder, Encoders.Map<Encoder, Void, Encoder.Data>> where Decoder.Metadata == Void, Encoder.Metadata == Data? {
        coder.mapEncoder { $0.setMetadata(nil) }
    }
    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoder, Encoders.Map<Encoder, Void, Encoder.Data>> where Decoder.Metadata == Void, Encoder.Metadata == [CompositeMetadata] {
        coder.mapEncoder { $0.setMetadata([]) }
    }

    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoders.Map<Decoder, Void, Decoder.Data>, Encoders.Map<Encoder, Void, Encoder.Data>> where Decoder.Metadata == Data?, Encoder.Metadata == Data? {
        coder.mapEncoder { $0.setMetadata(nil) }.mapDecoder{ $0.eraseMetadata() }
    }
    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoders.Map<Decoder, Void, Decoder.Data>, Encoders.Map<Encoder, Void, Encoder.Data>> where Decoder.Metadata == [CompositeMetadata], Encoder.Metadata == [CompositeMetadata] {
        coder.mapEncoder { $0.setMetadata([]) }.mapDecoder{ $0.eraseMetadata() }
    }

    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoders.Map<Decoder, Void, Decoder.Data>, Encoders.Map<Encoder, Void, Encoder.Data>> where Decoder.Metadata == [CompositeMetadata], Encoder.Metadata == Data? {
        coder.mapEncoder { $0.setMetadata(nil) }.mapDecoder{ $0.eraseMetadata() }
    }
    static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoders.Map<Decoder, Void, Decoder.Data>, Encoders.Map<Encoder, Void, Encoder.Data>> where Decoder.Metadata == Date?, Encoder.Metadata == [CompositeMetadata] {
        coder.mapEncoder { $0.setMetadata([]) }.mapDecoder{ $0.eraseMetadata() }
    }
}

struct FireAndForget<Request> {
    let encoder: AnyEncoder<Payload, Void, Request>
}

extension FireAndForget {
    init<Encoder>(
        @EncoderBuilder _ makeEncoder: () -> Encoder
    ) where Encoder: EncoderProtocol, Encoder.Response == Payload, Encoder.Metadata == Void, Encoder.Data == Request {
        encoder = makeEncoder().eraseToAnyEncoder()
    }
}

struct RequestResponse<Request, Response> {
    let encoder: AnyEncoder<Payload, Void, Request>
    let decoder: AnyDecoder<Payload, Void, Response>
}

extension RequestResponse {
    init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
Encoder.Response == Payload, Encoder.Metadata == Void, Encoder.Data == Request,
Decoder.Request == Payload, Decoder.Metadata == Void, Decoder.Data == Response {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

struct RequestStream<Request, Response> {
    let encoder: AnyEncoder<Payload, Void, Request>
    let decoder: AnyDecoder<Payload, Void, Response>
}

extension RequestStream {
    init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
Encoder.Response == Payload, Encoder.Metadata == Void, Encoder.Data == Request,
Decoder.Request == Payload, Decoder.Metadata == Void, Decoder.Data == Response {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

struct RequestChannel<Request, Response> {
    let encoder: AnyEncoder<Payload, Void, Request>
    let decoder: AnyDecoder<Payload, Void, Response>
}

extension RequestChannel {
    init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
Encoder.Response == Payload, Encoder.Metadata == Void, Encoder.Data == Request,
Decoder.Request == Payload, Decoder.Metadata == Void, Decoder.Data == Response {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

struct Metrics: Encodable {
    var os: String
}

enum Requests {
    static let metrics1: FireAndForget<Metrics> = .init {
        Encoder()
            .encodeMetadata(using: .routing)
            .setMetadata(["metrics"])
            .encodeData(using: .json(type: Metrics.self))
    }
    static let metrics2: FireAndForget<Metrics> = .init {
        Encoder()
            .useCompositeMetadata()
            .encodeMetadata(["metrics"], using: .routing)
            .encodeData(using: .json(type: Metrics.self))
    }
    static let metrics3: FireAndForget<([CompositeMetadata], Metrics)> = .init {
        Encoder()
            .useCompositeMetadata()
            .encodeMetadata(["metrics"], using: .routing)
            .encodeData(using: .json(type: Metrics.self))
            .preserveMetadata()
    }
    static let priceRequest1: RequestResponse<String, Double> = .init{
        Encoder()
            .useCompositeMetadata()
            .encodeMetadata(["price"], using: .routing)
            .encodeMetadata([.json], using: .acceptableDataMIMEType)
            .encodeData(using: .json(type: ISIN.self))
            .mapData(ISIN.init(isin:))
        Decoder()
            .useCompositeMetadata()
            .decodeData(using: .json(type: Price.self))
            .mapData(\.price)
    }
    static let priceRequest2: RequestResponse<String, Double> = .init{
        Coder()
            .useCompositeMetadata()
            .decodeData(using: [.json(type: Price.self)])
            .mapEncoder {
                $0.encodeMetadata(["price"], using: .routing)
                    .encodeData(using: .json(type: ISIN.self))
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
            .decodeData(using: [.json(type: Price.self)])
            .mapEncoder {
                $0.encodeMetadata(["price"], using: .routing)
                    .encodeData(using: .json(type: ISIN.self))
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
            .decodeData(using: [.json(type: Price.self)])
            .mapEncoder {
                $0.encodeMetadata(["price"], using: .routing)
                    .encodeData(using: .json(type: ISIN.self))
                    .mapData(ISIN.init(isin:))
            }
            .mapDecoder {
                $0.mapData(\.price).eraseMetadata()
            }
    }
    static let priceRequest5: RequestResponse<String, Double> = .init{
        Coder()
            .useCompositeMetadata()
            .decodeData(using: [.json(type: Price.self)])
            .mapEncoder {
                $0.encodeMetadata(["price"], using: .routing)
                    .encodeData(using: .json(type: ISIN.self))
                    .mapData(ISIN.init(isin:))
            }
            .mapDecoder {
                $0.mapData(\.price)
            }
    }
}

let coder = Coder()
    .useCompositeMetadata()
    .decodeData(using: [.json(type: Price.self)])
    .mapEncoder {
        $0.encodeMetadata(["price"], using: .routing)
            .encodeData(using: .json(type: ISIN.self))
            .mapData(ISIN.init(isin:))
            .setMetadata([])
    }
    .mapDecoder {
        $0.mapData(\.price).eraseMetadata()
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

func example() {

    let priceRequest = Coder()
        .useCompositeMetadata()
        // shorthand for:
        // .encodeMetadata(using: CompositeMetadataEncoder())
        // .decodeMetadata(using: CompositeMetadataDecoder())
        // .mapOutputMetadata { $0 ?? [] }
        .mapEncoder {
            $0.encodeMetadata(["stock.isin"], using: RoutingEncoder())
                // With Swift 5.5 we can write it like this:
                //.encodeMetadata(["stock.isin"], using: .routing)
                .encodeData(using: .json(type: ISIN.self))
        }
        .decodeData(using: [.json(type: Price.self)])
        .mapDecoder{ $0.mapData(\.price) }
        .mapEncoder { $0.mapData(ISIN.init(isin:)) }
        .mapEncoder { $0.eraseToAnyEncoder() }
        .mapDecoder { $0.eraseToAnyDecoder() }
}

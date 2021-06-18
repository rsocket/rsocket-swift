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


// MARK: - erase

//extension Request {
//    func setInputMetadata(to metadata: InputMetadata) -> Request<Void, InputData, OutputMetadata, OutputData> {
//        mapInputMetadata { metadata }
//    }
//}
//
//extension Request where InputMetadata == Data? {
//    func eraseInputMetadata() -> Request<Void, InputData, OutputMetadata, OutputData> {
//        setInputMetadata(to: nil)
//    }
//}
//
//extension Request where InputMetadata == [CompositeMetadata] {
//    func eraseInputMetadata() -> Request<Void, InputData, OutputMetadata, OutputData> {
//        setInputMetadata(to: [])
//    }
//}
//
//extension Request {
//    func eraseOutputMetadata() -> Request<InputMetadata, InputData, Void, OutputData> {
//        mapOutputMetadata { _ in }
//    }
//}
//
//typealias AnyRequest<RequestData, ResponseData> = Request<Void, RequestData, Void, ResponseData>
//
//extension Request where InputMetadata == [CompositeMetadata], OutputMetadata == [CompositeMetadata] {
//    func eraseMetadata() -> AnyRequest<InputData, OutputData>  {
//        self
//            .eraseInputMetadata()
//            .eraseOutputMetadata()
//    }
//}
//
//extension Request {
//    func preserveOutputMetadata() -> Request<InputMetadata, InputData, Void, (OutputMetadata, OutputData)> {
//        mapOutput { ((), ($0, $1)) }
//    }
//}

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
}

//protocol RequestDescription {
//    associatedtype InputMetadata
//    associatedtype InputData
//
//    func mapInput<NewInputMetadata, NewInputData>(
//        _ transform: @escaping (NewInputMetadata, NewInputData) throws -> (InputMetadata, InputData)
//    ) -> Self where Self.InputMetadata == NewInputMetadata, Self.InputData == NewInputData
//}
//
//protocol ResponseDescription {
//    associatedtype OutputMetadata
//    associatedtype OutputData
//
//    func mapOutput<NewOutputMetadata, NewOutputData>(
//        _ transform: @escaping (OutputMetadata, OutputData) throws -> (NewOutputMetadata, NewOutputData)
//    ) -> Self where Self.InputMetadata == NewInputMetadata, Self.InputData == NewInputData
//}
//
//struct FireAndForget<InputMetadata, InputData>: RequestDescription {
//}

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

struct AnyDecoder<Request, Metadata, Data> {
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

extension EncoderProtocol where Metadata == [CompositeMetadata], Data == Foundation.Data {
    func encodeData<NewData>(
        using encoder: DataEncoder<NewData>,
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init()
    ) -> Encoders.MapData<Encoders.MapMetadata<Self, [CompositeMetadata]>, NewData> {
        encodeMetadata(encoder.mimeType, using: dataMIMETypeEncoder)
            .mapData(encoder.encode)
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

enum RouteHandlerKind {
    case fireAndForget
    case requestResponse
    case requestStream
    case requestChannel
}

protocol RouteHandler {
    //var kind: RouteHandlerKind { get }
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

extension RequestResponseResponderDescription {
    init(@ResponderBuilder _ description: () -> RequestResponseResponderDescription<Decoder, Encoder, Handler>) {
        self = description()
    }
}

@resultBuilder
struct ResponderBuilder {
    static func buildBlock<Decoder, Encoder, Handler>(
        _ decoder: Decoder,
        _ encoder: Encoder,
        _ handler: Handler
    ) -> RequestResponseResponderDescription<Decoder, Encoder, Handler> {
        .init(decoder: decoder, encoder: encoder, handler: handler)
    }
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

struct RequestResponse<Decoder, Encoder> where Decoder: DecoderProtocol, Encoder: EncoderProtocol {
    let coder: Coder<Decoder, Encoder>
}

extension RequestResponse {
    init(decoder: Decoder, encoder: Encoder) {
        self.init(coder: .init(decoder: decoder, encoder: encoder))
    }
}

extension RequestResponse {
    func responder(
        handler: @escaping (Decoder.Data) async throws -> Encoder.Data
    ) -> RequestResponseResponderDescription<Decoder, Encoder, AsyncAwaitRequestResponseHandler<Decoder.Data, Encoder.Data>> {
            .init(decoder: coder.decoder, encoder: coder.encoder, handler: .init(handler: handler))
    }
}

@available(macOS 12.0, *)
func exampleRouter() -> Router {
    let responder = RequestResponseResponderDescription(
        decoder: Decoder(),
        encoder: Encoder(),
        handler: AsyncAwaitRequestResponseHandler { (request: Payload) -> Payload in
            request
        }
    )
    let responder2 = RequestResponseResponderDescription {
        Decoder()
        Encoder()
        AsyncAwaitRequestResponseHandler { (request: Payload) -> Payload in
            request
        }
    }

    let responder3 = RequestResponse(
        decoder: Decoder(),
        encoder: Encoder()
    ).responder { request in
        request
    }

    let routes = [Route(path: ["stock.isin"], handler: [responder, responder2, responder3])]
    return Router(routes: routes)
}

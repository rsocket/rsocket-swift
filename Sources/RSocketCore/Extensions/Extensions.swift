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


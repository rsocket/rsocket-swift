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

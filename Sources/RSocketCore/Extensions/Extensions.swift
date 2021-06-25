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

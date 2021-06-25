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

/**
 This file contains examples of the `Coder`, `Encoder` and `Decoder` API. 
 This all those examples should eventually be moved to documentation and also tests. 
 For now they are here to make sure we do not accidentally break any public API during development.
 */

fileprivate struct Metrics: Codable {
    var device: String
    var os: String
}

fileprivate struct Stock: Codable {
    var isin: ISIN
}
fileprivate struct ISIN: Codable {
    var isin: String
}
fileprivate struct Price: Codable {
    var price: Double
    var relativePerformance: Double
    var absolutePerformance: Double
}

fileprivate enum Requests {
    /// Routing Metadata is encoded directly without using Composite Metadata. Data is encoded as JSON.
    static let metrics1 = FireAndForget<Metrics> {
        Encoder()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: Metrics.self))
    }
    /// Routing Metadata is encoded through Composite Metadata. Data is encoded as JSON.
    static let metrics2 = FireAndForget<Metrics> {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: Metrics.self))
    }
    /// Same as above but gives the call site the option to encode additional dynamic metadata 
    static let metrics3 = FireAndForget<([CompositeMetadata], Metrics)> {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["metrics"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: Metrics.self))
            .preserveMetadata()
    }
    
    /// Routing Metadata and Acceptable Data MIME Type is encoded through composite Metadata.
    /// Data is encoded as JSON. The encoded Data is also transformed through the map operator before it is send to the JSON Encoder.
    /// Decoder does not use any Metadata but decodes data as JSON. The decoded data is then transformed through the map operator.
    /// Note: Encoder and Decoder can be defined in any order.
    static let priceRequest1 = RequestResponse<String, Double> {
        Encoder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeStaticMetadata([.json], using: .acceptableDataMIMEType)
            .encodeData(using: JSONDataEncoder(type: Stock.self))
            .mapData(Stock.init(isin:))
            .mapData(ISIN.init(isin:))
        Decoder()
            .decodeData(using: JSONDataDecoder(type: Price.self))
            .mapData(\.price)
    }
    /// Same as above but we do no longer need to explicitly encode the Acceptable Data MIME Type. 
    /// This is because we use the `Coder` convenience API which is a thin wrapper around an `Encoder` and `Decoder`.
    /// `Coder.decodeData(decoder:)` takes multiple decoders and automatically encodes their MIME Type as Acceptable Data MIME Type Metadata.
    /// It also looks for Data MIME Type and the Connection MIME Type and choose the correct decoder during decoding.
    static let priceRequest2 = RequestResponse<String, Double> {
        Coder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: ISIN.self).map(ISIN.init(isin:)))
            .decodeData {
                JSONDataDecoder(type: Price.self).map(\.price)
            }
    }
    
    /// Same as above but this time the encoder also encodes the MIME Type of the data as Date MIME Type Metadata because we use the `encodeData(encoder:)` method which can take multiple encoders. The call side need to specify which encoding it wants to use.
    static let priceRequest3 = RequestResponse<(MIMEType, String), Double> {
        Coder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeData {
                JSONDataEncoder(type: ISIN.self).map(ISIN.init(isin:))
            }
            .decodeData {
                JSONDataDecoder(type: Price.self)
                    .map(\.price)
            }
    }
    /// Works with `RequestStream` and `RequestChannel` too
    static let priceStream1 = RequestStream<ISIN, Price> {
        Coder()
            .useCompositeMetadata()
            .encodeStaticMetadata(["price"], using: .routing)
            .encodeData(using: JSONDataEncoder(type: ISIN.self))
            .decodeData(using: JSONDataDecoder(type: Price.self))
    }
    static let advancedRequest = RequestResponse<(([String], MIMEType), (MIMEType, Price)), (([String], [MIMEType], MIMEType), Stock)> {
        Coder()
            .useCompositeMetadata()
            .encodeData {
                JSONDataEncoder(type: Price.self)
            }
            .encodeMetadata {
                RoutingEncoder()
                DataMIMETypeEncoder()
            }
            .decodeData(using: JSONDataDecoder(type: Stock.self))
            .decodeMetadata {
                RoutingDecoder()
                AcceptableDataMIMETypeDecoder()
                DataMIMETypeDecoder()
            }
    }
}

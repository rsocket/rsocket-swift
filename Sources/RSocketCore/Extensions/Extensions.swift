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

struct CompositeMetadata {
    var mimeType: MIMEType
    var data: Data
}

// MARK: - MIMEType

struct MIMETypeEncoder {
    private static let defaultWellKnownMimeTypes = Dictionary(
        uniqueKeysWithValues: MIMEType.wellKnownMIMETypes.lazy.map{ ($0.1, $0.0) }
    )
    var wellKnownMimeTypes: [MIMEType: WellKnownMIMETypeCode] = defaultWellKnownMimeTypes
    func encode(_ mimeType: MIMEType, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct MIMETypeDecoder {
    private static let defaultWellKnownMimeTypes = Dictionary(uniqueKeysWithValues: MIMEType.wellKnownMIMETypes)
    var wellKnownMimeTypes: [WellKnownMIMETypeCode: MIMEType] = defaultWellKnownMimeTypes
    func decode(from buffer: inout ByteBuffer) throws -> MIMEType {
        fatalError("not implemented")
    }
}

// MARK: - Metadata Coder

protocol MetadataEncoder {
    associatedtype Metadata
    var mimeType: MIMEType { get }
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws
}

protocol MetadataDecoder {
    associatedtype Metadata
    var mimeType: MIMEType { get }
    func decode(from buffer: inout ByteBuffer) throws -> Metadata
}

extension MetadataEncoder {
    func encode(_ metadata: Metadata) throws -> Data {
        var buffer = ByteBuffer()
        try self.encode(metadata, into: &buffer)
        return buffer.readData(length: buffer.readableBytes) ?? Data()
    }
}

extension MetadataDecoder {
    func decode(from data: Data) throws -> Metadata {
        var buffer = ByteBuffer(data: data)
        let metadata = try self.decode(from: &buffer)
        guard buffer.readableBytes == 0 else {
            throw Error.invalid(message: "\(Decoder.self) did not read all bytes")
        }
        return metadata
    }
}

// MARK: - Composite Metadata

struct CompositeMetadataEncoder: MetadataEncoder {
    typealias Metadata = [CompositeMetadata]
    var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

// Swift 5.5 does support static member lookup in a generic context: https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md
extension MetadataEncoder where Self == CompositeMetadataEncoder {
    static var compositeMetadata: Self { .init() }
}

extension MetadataDecoder where Self == CompositeMetadataDecoder {
    static var compositeMetadata: Self { .init() }
}

extension CompositeMetadata {
    static func encoded<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) throws -> Self where Encoder: MetadataEncoder {
        CompositeMetadata(
            mimeType: encoder.mimeType,
            data: try encoder.encode(metadata)
        )
    }
}

extension RangeReplaceableCollection where Element == CompositeMetadata {
    func encoded<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) throws -> Self where Encoder: MetadataEncoder {
        self + CollectionOfOne(try CompositeMetadata.encoded(metadata, using: encoder))
    }
}

struct CompositeMetadataDecoder: MetadataDecoder {
    typealias Metadata = [CompositeMetadata]
    var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    var mimeTypeDecoder = MIMETypeEncoder()
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension Sequence where Element == CompositeMetadata {
    func decodeFirst<Decoder>(
        using decoder: Decoder
    ) throws -> Decoder.Metadata? where Decoder: MetadataDecoder {
        guard let data = first(where: { $0.mimeType == decoder.mimeType })?.data else {
            return nil
        }
        return try decoder.decode(from: data)
    }
}

// MARK: - Routing

struct RoutingEncoder: MetadataEncoder {
    typealias Metadata = [String]
    var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct RoutingDecoder: MetadataDecoder {
    typealias Metadata = [String]
    var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == RoutingEncoder {
    static var routing: Self { .init() }
}

extension MetadataDecoder where Self == RoutingDecoder {
    static var routing: Self { .init() }
}

// MARK: - Data MIME Type Encoder

struct DataMIMETypeEncoder: MetadataEncoder {
    typealias Metadata = MIMEType
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct DataMIMETypeDecoder: MetadataDecoder {
    typealias Metadata = MIMEType
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeDecoder = MIMETypeEncoder()
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == DataMIMETypeEncoder {
    static var dataMIMEType: Self { .init() }
}

extension MetadataDecoder where Self == DataMIMETypeDecoder {
    static var dataMIMEType: Self { .init() }
}

// MARK: - Acceptable Data MIME Type

struct AcceptableDataMIMETypeEncoder: MetadataEncoder {
    typealias Metadata = [MIMEType]
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeEncoder = MIMETypeEncoder()
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

struct AcceptableDataMIMETypeDecoder: MetadataDecoder {
    typealias Metadata = [MIMEType]
    var mimeType: MIMEType { .messageXRSocketMimeTypeV0 }
    var mimeTypeDecoder = MIMETypeEncoder()
    func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == AcceptableDataMIMETypeEncoder {
    static var acceptableDataMIMEType: Self { .init() }
}

extension MetadataDecoder where Self == AcceptableDataMIMETypeDecoder {
    static var acceptableDataMIMEType: Self { .init() }
}


// MARK: - Route

struct Request<InputMetadata, InputData, OutputMetadata, OutputData> {
    private var transformInput: (InputMetadata, InputData) throws -> Payload
    private var transformOutput: (Payload) throws -> (OutputMetadata, OutputData)
    internal init(
        transformInput: @escaping (InputMetadata, InputData) throws -> Payload,
        transformOutput: @escaping (Payload) throws -> (OutputMetadata, OutputData)
    ) {
        self.transformInput = transformInput
        self.transformOutput = transformOutput
    }
    init() where InputMetadata == Data?, InputData == Data, OutputMetadata == Data?, OutputData == Data {
        self.init(transformInput: { Payload(metadata: $0, data: $1) }, transformOutput: { ($0.metadata, $0.data) })
    }
}

extension Request {
    func map<NewInputMetadata, NewInputData, NewOutputMetadata, NewOutputData>(
        transformInput: @escaping (NewInputMetadata, NewInputData) throws -> (InputMetadata, InputData),
        transformOutput: @escaping (OutputMetadata, OutputData) throws -> (NewOutputMetadata, NewOutputData)
    ) -> Request<NewInputMetadata, NewInputData, NewOutputMetadata, NewOutputData> {
        .init { newMetadata, newData in
            let (metadata, data) = try transformInput(newMetadata, newData)
            return try self.transformInput(metadata, data)
        } transformOutput: { payload in
            let (metadata, data) = try self.transformOutput(payload)
            return try transformOutput(metadata, data)
        }
    }
    func map<NewInputMetadata, NewInputData, NewOutputMetadata, NewOutputData>(
        transformInputMetadata: @escaping (NewInputMetadata) throws -> InputMetadata,
        transformInputData: @escaping (NewInputData) throws -> InputData,
        transformOutputMetadata: @escaping (OutputMetadata) throws -> NewOutputMetadata,
        transformOutputData: @escaping (OutputData) throws -> NewOutputData
    ) -> Request<NewInputMetadata, NewInputData, NewOutputMetadata, NewOutputData> {
        map { newMetadata, newData in
            (try transformInputMetadata(newMetadata), try transformInputData(newData))
        } transformOutput: { metadata, data in
            (
                try transformOutputMetadata(metadata),
                try transformOutputData(data)
            )
        }
    }
    func mapOutput<NewOutputMetadata, NewOutputData>(
        _ transform: @escaping (OutputMetadata, OutputData) throws -> (NewOutputMetadata, NewOutputData)
    ) -> Request<InputMetadata, InputData, NewOutputMetadata, NewOutputData> {
        .init(transformInput: self.transformInput) { payload in
            let (metadata, data) = try self.transformOutput(payload)
            return try transform(metadata, data)
        }
    }
    func mapInput<NewInputMetadata, NewInputData>(
        _ transform: @escaping (NewInputMetadata, NewInputData) throws -> (InputMetadata, InputData)
    ) -> Request<NewInputMetadata, NewInputData, OutputMetadata, OutputData> {
        .init(
            transformInput: { newMetadata, newData in
                let (metadata, data) = try transform(newMetadata, newData)
                return try self.transformInput(metadata, data)
            },
            transformOutput: transformOutput
        )
    }
}

extension Request {
    func mapMetadata<NewInputMetadata, NewOutputMetadata>(
        transformInputMetadata: @escaping (NewInputMetadata) throws -> InputMetadata,
        transformOutputMetadata: @escaping (OutputMetadata) throws -> NewOutputMetadata
    ) -> Request<NewInputMetadata, InputData, NewOutputMetadata, OutputData> {
        map(
            transformInputMetadata: transformInputMetadata,
            transformInputData: { $0 },
            transformOutputMetadata: transformOutputMetadata,
            transformOutputData: { $0 }
        )
    }
    func mapData<NewInputData, NewOutputData>(
        transformInputData: @escaping (NewInputData) throws -> InputData,
        transformOutputData: @escaping (OutputData) throws -> NewOutputData
    ) -> Request<InputMetadata, NewInputData, OutputMetadata, NewOutputData> {
        map(
            transformInputMetadata: { $0 },
            transformInputData: transformInputData,
            transformOutputMetadata: { $0 },
            transformOutputData: transformOutputData
        )
    }
    func mapInputMetadata<NewInputMetadata>(
        _ transformInputMetadata: @escaping (NewInputMetadata) throws -> InputMetadata
    ) -> Request<NewInputMetadata, InputData, OutputMetadata, OutputData> {
        mapMetadata(
            transformInputMetadata: transformInputMetadata,
            transformOutputMetadata: { $0 }
        )
    }
    func mapOutputMetadata<NewOutputMetadata>(
        _ transformOutputMetadata: @escaping (OutputMetadata) throws -> NewOutputMetadata
    ) -> Request<InputMetadata, InputData, NewOutputMetadata, OutputData> {
        mapMetadata(
            transformInputMetadata: { $0 },
            transformOutputMetadata: transformOutputMetadata
        )
    }
    func mapInputData<NewInputData>(
        _ transformInputData: @escaping (NewInputData) throws -> InputData
    ) -> Request<InputMetadata, NewInputData, OutputMetadata, OutputData> {
        mapData(
            transformInputData: transformInputData,
            transformOutputData: { $0 }
        )
    }
    func mapOutputData<NewOutputData>(
        _ transformOutputData: @escaping (OutputData) throws -> NewOutputData
    ) -> Request<InputMetadata, InputData, OutputMetadata, NewOutputData> {
        mapData(
            transformInputData: { $0 },
            transformOutputData: transformOutputData
        )
    }
}

extension Request where InputMetadata == Data? {
    func encodeMetadata<Encoder>(
        using encoder: Encoder
    ) -> Request<Encoder.Metadata, InputData, OutputMetadata, OutputData> where Encoder: MetadataEncoder {
        mapInputMetadata { metadata in
            try encoder.encode(metadata)
        }
    }
}

extension Request where OutputMetadata == Data? {
    func decodeMetadata<Decoder>(
        using decoder: Decoder
    ) -> Request<InputMetadata, InputData, Decoder.Metadata?, OutputData> where Decoder: MetadataDecoder {
        mapOutputMetadata { data in
            try data.map { try decoder.decode(from: $0) }
        }
    }
}

extension Request where InputMetadata == Data?, OutputMetadata == Data? {
    func useCompositeMetadata(
        decoder: CompositeMetadataDecoder = .init(),
        encoder: CompositeMetadataEncoder = .init()
    ) -> Request<[CompositeMetadata], InputData, [CompositeMetadata], OutputData> {
        encodeMetadata(using: encoder)
            .decodeMetadata(using: decoder)
            .mapOutputMetadata { $0 ?? [] }
    }
}

extension Request where InputMetadata == [CompositeMetadata] {
    func encodeMetadata<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) -> Self where Encoder: MetadataEncoder {
        mapInputMetadata { compositeMetadata in
            try compositeMetadata.encoded(metadata, using: encoder)
        }
    }
}

extension Request where InputMetadata == [CompositeMetadata] {
    func encodeMetadata<Encoder>(
        using encoder: Encoder
    ) -> Request<Encoder.Metadata, InputData, OutputMetadata, OutputData> where Encoder: MetadataEncoder {
        mapInputMetadata { metadata in
            [try CompositeMetadata.encoded(metadata, using: encoder)]
        }
    }
}

// MARK: - Data Encoder

struct DataEncoder<Value> {
    var mimeType: MIMEType
    private var _encode: (Value) throws -> Data
    
    init(mimeType: MIMEType, encode: @escaping (Value) throws -> Data) {
        self._encode = encode
        self.mimeType = mimeType
    }
    
    func encode(_ value: Value) throws -> Data {
        try _encode(value)
    }
}

extension DataEncoder {
    func map<NewValue>(
        _ transform: @escaping (NewValue) throws -> Value
    ) -> DataEncoder<NewValue> {
        .init(mimeType: mimeType) { value in
            try _encode(try transform(value))
        }
    }
}

extension DataEncoder {
    static func json(
        type: Value.Type = Value.self,
        using encoder: JSONEncoder = .init()
    ) -> Self where Value: Encodable {
        .init(mimeType: .applicationJson, encode: encoder.encode(_:))
    }
}

extension Request where InputMetadata == [CompositeMetadata], InputData == Data {
    func encodeData<NewInputData>(
        using encoder: DataEncoder<NewInputData>,
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init()
    ) -> Request<InputMetadata, NewInputData, OutputMetadata, OutputData> {
        encodeMetadata(.applicationJson, using: dataMIMETypeEncoder)
            .mapInputData(encoder.encode)
    }
}

// MARK: - Data Decoder

struct DataDecoder<Value> {
    var mimeType: MIMEType
    private var _decode: (Data) throws -> Value
    
    init(mimeType: MIMEType, decode: @escaping (Data) throws -> Value) {
        self._decode = decode
        self.mimeType = mimeType
    }
    
    func decode(from data: Data) throws -> Value {
        try _decode(data)
    }
}

extension DataDecoder {
    func map<NewValue>(
        _ transform: @escaping (Value) throws -> NewValue
    ) -> DataDecoder<NewValue> {
        .init(mimeType: mimeType) { data in
            try transform(try _decode(data))
        }
    }
}

extension DataDecoder {
    static func json(
        type: Value.Type = Value.self,
        using decoder: JSONDecoder = .init()
    ) -> Self where Value: Decodable {
        self.init(mimeType: .applicationJson) { data in
            try decoder.decode(Value.self, from: data)
        }
    }
}

extension Request where OutputData == Data, InputMetadata == [CompositeMetadata], OutputMetadata == [CompositeMetadata] {
    func decodeData<NewOutputValue>(
        using decoder: [DataDecoder<NewOutputValue>],
        acceptableDataMIMETypeEncoder: AcceptableDataMIMETypeEncoder = .init(),
        dataMIMETypeDecoder: DataMIMETypeDecoder = .init()
    ) -> Request<InputMetadata, InputData, OutputMetadata, NewOutputValue> {
        let supportedEncodings = decoder.map(\.mimeType)
        return encodeMetadata(supportedEncodings, using: acceptableDataMIMETypeEncoder)
            .mapOutput { metadata, data in
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

extension Request where OutputData == Data {
    /// unconditionally decodes data with the given `decoder`
    func decodeData<NewOutputValue>(
        using decoder: DataDecoder<NewOutputValue>
    ) -> Request<InputMetadata, InputData, OutputMetadata, NewOutputValue> {
        mapOutputData(decoder.decode(from:))
    }
}

// MARK: - erase

extension Request {
    func setInputMetadata(to metadata: InputMetadata) -> Request<Void, InputData, OutputMetadata, OutputData> {
        mapInputMetadata { metadata }
    }
}

extension Request where InputMetadata == Data? {
    func eraseInputMetadata() -> Request<Void, InputData, OutputMetadata, OutputData> {
        setInputMetadata(to: nil)
    }
}

extension Request where InputMetadata == [CompositeMetadata] {
    func eraseInputMetadata() -> Request<Void, InputData, OutputMetadata, OutputData> {
        setInputMetadata(to: [])
    }
}

extension Request {
    func eraseOutputMetadata() -> Request<InputMetadata, InputData, Void, OutputData> {
        mapOutputMetadata { _ in }
    }
}

typealias AnyRequest<RequestData, ResponseData> = Request<Void, RequestData, Void, ResponseData>

extension Request where InputMetadata == [CompositeMetadata], OutputMetadata == [CompositeMetadata] {
    func eraseMetadata() -> AnyRequest<InputData, OutputData>  {
        self
            .eraseInputMetadata()
            .eraseOutputMetadata()
    }
}

extension Request {
    func preserveOutputMetadata() -> Request<InputMetadata, InputData, Void, (OutputMetadata, OutputData)> {
        mapOutput { ((), ($0, $1)) }
    }
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

    let priceRequest = Request()
        .useCompositeMetadata()
        // shorthand for:
        // .encodeMetadata(using: CompositeMetadataEncoder())
        // .decodeMetadata(using: CompositeMetadataDecoder())
        // .mapOutputMetadata { $0 ?? [] }
        .encodeMetadata(["stock.isin"], using: RoutingEncoder())
        // With Swift 5.5 we can write it like this:
        //.encodeMetadata(["stock.isin"], using: .routing)
        .encodeData(using: .json(type: ISIN.self))
        .decodeData(using: [.json(type: Price.self)])
        .mapOutputData(\.price)
        .mapInputData(ISIN.init(isin:))
        .eraseMetadata()
}

extension Request where InputMetadata == Void {
    func payload(for data: InputData) throws -> Payload {
        try self.transformInput((), data)
    }
}

extension Request where OutputMetadata == Void {
    func output(from payload: Payload) throws -> OutputData {
        try transformOutput(payload).1
    }
}

extension Request {
    public static var price: Request<Void, String, Void, Double> {
        Request<Data?, Data, Data?, Data>()
            .useCompositeMetadata()
            .encodeMetadata(["stock.isin"], using: RoutingEncoder())
            .encodeData(using: .json(type: ISIN.self))
            .decodeData(using: [.json(type: Price.self)])
            .mapOutputData(\.price)
            .mapInputData(ISIN.init(isin:))
            .eraseMetadata()
    }
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

protocol PayloadDecoderDescriptionProtocol {
    associatedtype Request = Payload
    associatedtype Metadata
    associatedtype Data
    func decodeRequest(_ request: Request) throws -> (Metadata, Data)
}


/// Namespace
enum Decoders {}

extension Decoders {
    struct Start<Request, Metadata, Data>: PayloadDecoderDescriptionProtocol {
        var make: (Request) -> (Metadata, Data)
        func decodeRequest(_ request: Request) throws -> (Metadata, Data) {
            make(request)
        }
    }
    struct MapRequest<Decoder: PayloadDecoderDescriptionProtocol, Request>: PayloadDecoderDescriptionProtocol {
        var decoder: Decoder
        var transform: (Request) throws -> (Decoder.Request)
        func decodeRequest(_ request: Request) throws -> (Decoder.Metadata, Decoder.Data) {
            let request = try transform(request)
            return try decoder.decodeRequest(request)
        }
    }
    struct Map<Decoder: PayloadDecoderDescriptionProtocol, Metadata, Data>: PayloadDecoderDescriptionProtocol {
        typealias Request = Decoder.Request
        var decoder: Decoder
        var transform: (Decoder.Metadata, Decoder.Data) throws -> (Metadata, Data)
        func decodeRequest(_ request: Request) throws -> (Metadata, Data) {
            let (metadata, data) = try decoder.decodeRequest(request)
            return try transform(metadata, data)
        }
    }
    struct MapMetadata<Decoder: PayloadDecoderDescriptionProtocol, Metadata>: PayloadDecoderDescriptionProtocol {
        typealias Request = Decoder.Request
        var decoder: Decoder
        var transform: (Decoder.Metadata) throws -> Metadata
        func decodeRequest(_ request: Request) throws -> (Metadata, Decoder.Data) {
            let (metadata, data) = try decoder.decodeRequest(request)
            return (try transform(metadata), data)
        }
    }
    struct MapData<Decoder: PayloadDecoderDescriptionProtocol, Data>: PayloadDecoderDescriptionProtocol {
        typealias Request = Decoder.Request
        var decoder: Decoder
        var transform: (Decoder.Data) throws -> Data
        func decodeRequest(_ request: Request) throws -> (Decoder.Metadata, Data) {
            let (metadata, data) = try decoder.decodeRequest(request)
            return (metadata, try transform(data))
        }
    }
}

extension PayloadDecoderDescriptionProtocol {
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


struct PayloadDecoderDescription<Metadata, Data> {
    typealias Decode = (Payload) throws -> (Metadata, Data)
    var _decode: Decode
    init(_ decode: @escaping Decode) {
        self._decode = decode
    }
}

extension PayloadDecoderDescription {
    func decodePayload(_ payload: Payload) throws -> (Metadata, Data) {
        try _decode(payload)
    }
}


extension PayloadDecoderDescription {
    func map<NewMetadata, NewData>(
        _ transform: @escaping (Metadata, Data) throws -> (NewMetadata, NewData)
    ) -> PayloadDecoderDescription<NewMetadata, NewData> {
        .init { payload in
            let (metadata, data) = try self._decode(payload)
            return try transform(metadata, data)
        }
    }
}

extension PayloadDecoderDescription {
    func mapMetadata<NewMetadata>(
        _ transform: @escaping (Metadata) throws -> NewMetadata
    ) -> PayloadDecoderDescription<NewMetadata, Data> {
        map { (try transform($0), $1) }
    }
    func mapData<NewData>(
        _ transform: @escaping (Data) throws -> NewData
    ) -> PayloadDecoderDescription<Metadata, NewData> {
        map { ($0, try transform($1)) }
    }
}


// MARK: - Payload Encoder


protocol PayloadEncoderDescriptionProtocol {
    associatedtype Response = Payload
    associatedtype Metadata
    associatedtype Data
    func encodeResponse(metadata: Metadata, data: Data) throws -> Response
}

enum Encoders {
    struct Start<Response, Metadata, Data>: PayloadEncoderDescriptionProtocol {
        var make: (Metadata, Data) -> Response
        func encodeResponse(metadata: Metadata, data: Data) throws -> Response {
            make(metadata, data)
        }
    }
    struct MapResponse<Encoder: PayloadEncoderDescriptionProtocol, Response>: PayloadEncoderDescriptionProtocol {
        var encoder: Encoder
        var transform: (Encoder.Response) throws -> (Response)
        func encodeResponse(metadata: Encoder.Metadata, data: Encoder.Data) throws -> Response {
            try transform(try encoder.encodeResponse(metadata: metadata, data: data))
        }
    }
    struct Map<Encoder: PayloadEncoderDescriptionProtocol, Metadata, Data>: PayloadEncoderDescriptionProtocol {
        typealias Response = Encoder.Response
        var encoder: Encoder
        var transform: (Metadata, Data) throws -> (Encoder.Metadata, Encoder.Data)
        func encodeResponse(metadata: Metadata, data: Data) throws -> Response {
            let (metadata, data) = try transform(metadata, data)
            return try encoder.encodeResponse(metadata: metadata, data: data)
        }
    }
    struct MapMetadata<Encoder: PayloadEncoderDescriptionProtocol, Metadata>: PayloadEncoderDescriptionProtocol {
        typealias Response = Encoder.Response
        var encoder: Encoder
        var transform: (Metadata) throws -> Encoder.Metadata
        func encodeResponse(metadata: Metadata, data: Encoder.Data) throws -> Response {
            try encoder.encodeResponse(metadata: try transform(metadata), data: data)
        }
    }
    struct MapData<Encoder: PayloadEncoderDescriptionProtocol, Data>: PayloadEncoderDescriptionProtocol {
        typealias Response = Encoder.Response
        var encoder: Encoder
        var transform: (Data) throws -> Encoder.Data
        func encodeResponse(metadata: Encoder.Metadata, data: Data) throws -> Response {
            try encoder.encodeResponse(metadata: metadata, data: try transform(data))
        }
    }
}

extension PayloadEncoderDescriptionProtocol {
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


struct PayloadEncodeDescription<Metadata, Data> {
    typealias Encode = (Metadata, Data) throws -> Payload
    var _encode: Encode
    init(_ encode: @escaping Encode) {
        self._encode = encode
    }
}

extension PayloadEncodeDescription {
    func encodeAsPayload(metadata: Metadata, data: Data) throws -> Payload {
        try _encode(metadata, data)
    }
}

extension PayloadEncodeDescription {
    func map<NewMetadata, NewData>(
        _ transform: @escaping (NewMetadata, NewData) throws -> (Metadata, Data)
    ) -> PayloadEncodeDescription<NewMetadata, NewData> {
        return .init { newMetadata, newData in
            let (metadata, data) = try transform(newMetadata, newData)
            return try _encode(metadata, data)
        }
    }
}

extension PayloadEncodeDescription {
    func mapMetadata<NewMetadata>(
        _ transform: @escaping (NewMetadata) throws -> Metadata
    ) -> PayloadEncodeDescription<NewMetadata, Data> {
        map { (try transform($0), $1) }
    }
    func mapData<NewData>(
        _ transform: @escaping (NewData) throws -> Data
    ) -> PayloadEncodeDescription<Metadata, NewData> {
        map { ($0, try transform($1)) }
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

struct FireAndForget: RouteHandler {
    var kind: RouteHandlerKind { .fireAndForget }
    var handle: (Payload) -> ()
}

struct RequestResponse: RouteHandler {
    var kind: RouteHandlerKind { .requestResponse }
    var handle: (Payload) async throws -> Payload
}

@available(macOS 12.0, *)
struct RequestStream: RouteHandler {
    var kind: RouteHandlerKind { .requestStream }
    var handle: (Payload) async throws -> YieldingContinuation<Payload, Swift.Error>
}


extension RequestResponse {
    init<RequestMetadata, RequestData, ResponseMetadata, ResponseData>(
        decoder: (PayloadDecoderDescription<Data?, Data>) -> PayloadDecoderDescription<RequestMetadata, RequestData>,
        encoder: (PayloadEncodeDescription<Data?, Data>) -> PayloadEncodeDescription<ResponseMetadata, ResponseData>,
        handler: @escaping (RequestMetadata, RequestData) async throws -> (metadata: ResponseMetadata, data: ResponseData)
    ) {
        let decoder = decoder(PayloadDecoderDescription{ ($0.metadata, $0.data) })
        let encoder = encoder(PayloadEncodeDescription{ Payload(metadata: $0, data: $1) })
        self.init { payload in
            let (metadata, data) = try decoder.decodePayload(payload)
            let response = try await handler(metadata, data)
            return try encoder.encodeAsPayload(metadata: response.metadata, data: response.data)
        }
    }
}

protocol RequestResponseHandler {
    associatedtype Request
    associatedtype Response
    func handleRequest(_ request: Request) async throws -> Response
}

struct RequestResponseResponderDescription<
    Decoder: PayloadDecoderDescriptionProtocol,
    Encoder: PayloadEncoderDescriptionProtocol,
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
    let routes = [Route(path: ["stock.isin"], handler: [responder])]
    return Router(routes: routes)
}

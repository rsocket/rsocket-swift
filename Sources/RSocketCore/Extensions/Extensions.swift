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
        .init { newMetadata, newData in
            try self.transformInput(try transformInputMetadata(newMetadata), try transformInputData(newData))
        } transformOutput: { payload in
            let (metadata, data) = try self.transformOutput(payload)
            return (
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
    func mapInput<NewOutputMetadata, NewOutputData>(
        _ transform: @escaping (OutputMetadata, OutputData) throws -> (NewOutputMetadata, NewOutputData)
    ) -> Request<InputMetadata, InputData, NewOutputMetadata, NewOutputData> {
        .init(transformInput: self.transformInput) { payload in
            let (metadata, data) = try self.transformOutput(payload)
            return try transform(metadata, data)
        }
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
        transformInputMetadata: @escaping (NewInputMetadata) throws -> InputMetadata
    ) -> Request<NewInputMetadata, InputData, OutputMetadata, OutputData> {
        mapMetadata(
            transformInputMetadata: transformInputMetadata,
            transformOutputMetadata: { $0 }
        )
    }
    func mapOutputMetadata<NewOutputMetadata>(
        transformOutputMetadata: @escaping (OutputMetadata) throws -> NewOutputMetadata
    ) -> Request<InputMetadata, InputData, NewOutputMetadata, OutputData> {
        mapMetadata(
            transformInputMetadata: { $0 },
            transformOutputMetadata: transformOutputMetadata
        )
    }
    func mapInputData<NewInputData>(
        transformInputData: @escaping (NewInputData) throws -> InputData
    ) -> Request<InputMetadata, NewInputData, OutputMetadata, OutputData> {
        mapData(
            transformInputData: transformInputData,
            transformOutputData: { $0 }
        )
    }
    func mapOutputData<NewOutputData>(
        transformOutputData: @escaping (OutputData) throws -> NewOutputData
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
    func encode<Encoder>(
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

extension Request where InputMetadata == [CompositeMetadata], InputData == Data {
    func encodeAsJSON<NewInputData>(
        type: NewInputData.Type = NewInputData.self,
        using encoder: JSONEncoder = .init(),
        dataMIMETypeEncoder: DataMIMETypeEncoder = .init()
    ) -> Request<InputMetadata, NewInputData, OutputMetadata, OutputData> where NewInputData: Encodable {
        encode(.applicationJson, using: dataMIMETypeEncoder)
            .mapInputData(transformInputData: encoder.encode)
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
        acceptableDataMIMETypeEncoder: AcceptableDataMIMETypeEncoder = .init()
    ) -> Request<InputMetadata, InputData, OutputMetadata, NewOutputValue> {
        let supportedEncodings = decoder.map(\.mimeType)
        return encode(supportedEncodings, using: acceptableDataMIMETypeEncoder)
            .mapOutput { metadata, data in
                guard let dataEncoding = try metadata.decodeFirst(using: DataMIMETypeDecoder()) else {
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
    func decodeAsJSON<NewOutputData>(
        type: NewOutputData.Type = NewOutputData.self,
        using decoder: JSONDecoder = .init()
    ) -> Request<InputMetadata, InputData, OutputMetadata, NewOutputData> where NewOutputData: Decodable {
        mapOutputData { data in
            try decoder.decode(NewOutputData.self, from: data)
        }
    }
}

// MARK: - finalize

extension Request {
    func finalizeInputMetadata(_ metadata: InputMetadata) -> Request<Void, InputData, OutputMetadata, OutputData> {
        mapInputMetadata { metadata }
    }
}

extension Request where InputMetadata == Data? {
    func finalizeInputMetadata() -> Request<Void, InputData, OutputMetadata, OutputData> {
        finalizeInputMetadata(nil)
    }
}

extension Request where InputMetadata == [CompositeMetadata] {
    func finalizeInputMetadata() -> Request<Void, InputData, OutputMetadata, OutputData> {
        finalizeInputMetadata([])
    }
}

extension Request {
    func finalizeInputData(_ inputData: InputData) -> Request<InputMetadata, Void, OutputMetadata, OutputData> {
        mapInputData(transformInputData: { inputData })
    }
}

extension Request {
    func finalizeOutputMetadata() -> Request<InputMetadata, InputData, Void, OutputData> {
        mapOutputMetadata { _ in }
    }
}


func example() {
    struct Stock: Codable {
        var isin: ISIN
    }
    struct ISIN: Codable {
        var isin: String
    }
    struct Price: Codable {
        var price: Double
    }
    let priceRequest = Request()
        .useCompositeMetadata()
        // shorthand for:
        // .encodeMetadata(using: CompositeMetadataEncoder())
        // .decodeMetadata(using: CompositeMetadataDecoder())
        // .mapOutputMetadata { $0 ?? [] }
        //.encode(["stock.isin"], using: RoutingEncoder())
        // With Swift 5.5 we can write it like this:
        .encode(["stock.isin"], using: .routing)
        //.encodeMetadata(using: .routing)
        //.finalizeInputMetadata(["stock.isin"])
        .decodeData(using: [DataDecoder.json(type: Price.self)])
        .encodeAsJSON(type: ISIN.self)
        
        .finalizeOutputMetadata()
        .mapInputData{ (stock: Stock) in stock.isin }
    
    let request = priceRequest.finalizeInputData(.init(isin: .init(isin: "CA0585861085")))
}

extension Request where InputMetadata == Void, InputData == Void {
    func payload() throws -> Payload {
        try self.transformInput((), ())
    }
}

extension Request where OutputMetadata == Void {
    func decodeOutput(from payload: Payload) throws -> OutputData {
        try transformOutput(payload).1
    }
}

struct NoOpCancelable: Cancellable {
    func onCancel() {}
    func onError(_ error: Error) {}
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {}
}

extension RSocket {
    func requestResponse<OutputData>(
        _ request: Request<Void, Void, Void, OutputData>,
        responderStream: UnidirectionalStream
    ) -> Cancellable {
        do {
            return requestResponse(payload: try request.payload(), responderStream: responderStream)
        } catch {
            responderStream.onError(.fromGenericApplicationError(error))
            return NoOpCancelable()
        }
    }
}

extension Error {
    static func fromGenericApplicationError(_ error: Swift.Error) -> Self {
        error as? Error ?? Error.applicationError(message: error.localizedDescription)
    }
}

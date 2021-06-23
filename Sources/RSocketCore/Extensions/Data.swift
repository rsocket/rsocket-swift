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

protocol DataEncoderProtocol: MultiDataEncoderProtocol {
    associatedtype Data
    var mimeType: MIMEType { get }
    func encode(_ data: Data, into buffer: inout ByteBuffer) throws
}

extension DataEncoderProtocol {
    func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool {
        guard mimeType == self.mimeType else { return false }
        try encode(data, into: &buffer)
        return true
    }
}

extension DataEncoderProtocol {
    func encode(_ data: Data) throws -> Foundation.Data {
        var buffer = ByteBuffer()
        try self.encode(data, into: &buffer)
        return buffer.readData(length: buffer.readableBytes) ?? Foundation.Data()
    }
}

protocol DataDecoderProtocol: MultiDataDecoderProtocol {
    associatedtype Data
    var mimeType: MIMEType { get }
    func decode(from buffer: inout ByteBuffer) throws -> Data
}

extension DataDecoderProtocol {
    var supportedMIMETypes: [MIMEType] { [mimeType] }
    func decodeMIMETypeIfSupported(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data? {
        guard mimeType == self.mimeType else { return nil }
        return try decode(from: &buffer)
    }
}

extension DataDecoderProtocol {
    func decode(from data: Foundation.Data) throws -> Data {
        var buffer = ByteBuffer(data: data)
        let data = try self.decode(from: &buffer)
        guard buffer.readableBytes == 0 else {
            throw Error.invalid(message: "\(Decoder.self) did not read all bytes")
        }
        return data
    }
}

struct JSONDataDecoder<Data: Decodable>: DataDecoderProtocol {
    var decoder: JSONDecoder = .init()
    var mimeType: MIMEType { .json }
    init(type: Data.Type = Data.self, decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }
    func decode(from buffer: inout ByteBuffer) throws -> Data {
        try decoder.decode(Data.self, from: buffer)
    }
}

extension DataDecoderProtocol {
    static func json(type: Data.Type, decoder: JSONDecoder = .init()) -> JSONDataDecoder<Data> where Data: Decodable {
            .init(decoder: decoder)
    }
}

struct JSONDataEncoder<Data: Encodable>: DataEncoderProtocol {
    var encoder: JSONEncoder
    var mimeType: MIMEType { .json }
    init(type: Data.Type = Data.self, encoder: JSONEncoder = .init()) {
        self.encoder = encoder
    }
    func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
        try encoder.encode(data, into: &buffer)
    }
}

enum DataEncoders {
    struct Map<Encoder: DataEncoderProtocol, Data>: DataEncoderProtocol {
        var encoder: Encoder
        var transform: (Data) -> Encoder.Data
        var mimeType: MIMEType { .json }
        func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
            try encoder.encode(transform(data), into: &buffer)
        }
    }
    struct TryMap<Encoder: DataEncoderProtocol, Data>: DataEncoderProtocol {
        var encoder: Encoder
        var transform: (Data) throws -> Encoder.Data
        var mimeType: MIMEType { .json }
        func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
            try encoder.encode(try transform(data), into: &buffer)
        }
    }
}

extension DataEncoderProtocol {
    func map<NewData>(
        _ transform: @escaping (NewData) -> Data
    ) -> DataEncoders.Map<Self, NewData> {
        .init(encoder: self, transform: transform)
    }
    func tryMap<NewData>(
        _ transform: @escaping (NewData) throws -> Data
    ) -> DataEncoders.TryMap<Self, NewData> {
        .init(encoder: self, transform: transform)
    }
}

enum DataDecoders {
    struct Map<Decoder: DataDecoderProtocol, Data>: DataDecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Data) -> Data
        var mimeType: MIMEType { decoder.mimeType }
        func decode(from buffer: inout ByteBuffer) throws -> Data {
            transform(try decoder.decode(from: &buffer))
        }
    }
    struct TryMap<Decoder: DataDecoderProtocol, Data>: DataDecoderProtocol {
        var decoder: Decoder
        var transform: (Decoder.Data) throws -> Data
        var mimeType: MIMEType { decoder.mimeType }
        func decode(from buffer: inout ByteBuffer) throws -> Data {
            try transform(try decoder.decode(from: &buffer))
        }
    }
}

extension DataDecoderProtocol {
    func map<NewData>(
        _ transform: @escaping (Data) -> NewData
    ) -> DataDecoders.Map<Self, NewData> {
        .init(decoder: self, transform: transform)
    }
    func tryMap<NewData>(
        _ transform: @escaping (Data) throws -> NewData
    ) -> DataDecoders.TryMap<Self, NewData> {
        .init(decoder: self, transform: transform)
    }
}

protocol MultiDataEncoderProtocol {
    associatedtype Data
    /// tries to encode `data` as `mimeType`.
    /// - Returns: true if it `mimeType` is a supported encoding and encoding was successful
    func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool
}

extension MultiDataEncoderProtocol {
    func encode(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws {
        guard try encodeIfSupported(data, as: mimeType, into: &buffer) else {
            throw Error.invalid(message: "could not encode data as \(mimeType)")
        }
    }
}

extension MultiDataEncoderProtocol {
    func encode(_ data: Data, as mimeType: MIMEType) throws -> Foundation.Data {
        var buffer = ByteBuffer()
        try self.encode(data, as: mimeType, into: &buffer)
        return buffer.readData(length: buffer.readableBytes) ?? .init()
    }
}

struct MultiDataEncoderTuple2<A, B>: MultiDataEncoderProtocol where
A: DataEncoderProtocol,
B: DataEncoderProtocol,
A.Data == B.Data
{
    typealias Data = A.Data
    let encoder: (A, B)
    func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool {
        switch mimeType {
        case encoder.0.mimeType:
            try encoder.0.encode(data, into: &buffer)
        case encoder.1.mimeType:
            try encoder.1.encode(data, into: &buffer)
        default:
            return false
        }
        return true
    }
}

struct MultiDataEncoderTuple3<A, B, C>: MultiDataEncoderProtocol where
A: DataEncoderProtocol,
B: DataEncoderProtocol,
C: DataEncoderProtocol,
A.Data == B.Data,
A.Data == C.Data
{
    typealias Data = A.Data
    let encoder: (A, B, C)
    func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool {
        switch mimeType {
        case encoder.0.mimeType:
            try encoder.0.encode(data, into: &buffer)
        case encoder.1.mimeType:
            try encoder.1.encode(data, into: &buffer)
        case encoder.2.mimeType:
            try encoder.2.encode(data, into: &buffer)
        default:
            return false
        }
        return true
    }
}

@resultBuilder
enum MultiDataEncoderBuilder {
    static func buildBlock<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: MultiDataEncoderProtocol {
        encoder
    }
    static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> MultiDataEncoderTuple2<A, B> {
        .init(encoder: (a, b))
    }
    static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> MultiDataEncoderTuple3<A, B, C> {
        .init(encoder: (a, b, c))
    }
}

protocol MultiDataDecoderProtocol {
    associatedtype Data
    var supportedMIMETypes: [MIMEType] { get }
    func decodeMIMETypeIfSupported(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data?
}

enum MultiDataDecoderError: Swift.Error {
    case mimeTypeNotSupported(MIMEType)
}

extension MultiDataDecoderProtocol {
    func decodeMIMEType(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data {
        guard let data = try decodeMIMETypeIfSupported(mimeType, from: &buffer) else {
            throw MultiDataDecoderError.mimeTypeNotSupported(mimeType)
        }
        return data
    }
}

extension MultiDataDecoderProtocol {
    func decodeMIMEType(_ mimeType: MIMEType, from data: Foundation.Data) throws -> Data {
        var buffer = ByteBuffer(data: data)
        let data = try self.decodeMIMEType(mimeType, from: &buffer)
        guard buffer.readableBytes == 0 else {
            throw Error.invalid(message: "\(Decoder.self) did not read all bytes")
        }
        return data
    }
}

struct MultiDataDecoderTuple2<A, B>: MultiDataDecoderProtocol where
A: DataDecoderProtocol,
B: DataDecoderProtocol,
A.Data == B.Data {
    typealias Data = A.Data
    let decoder: (A, B)
    var supportedMIMETypes: [MIMEType] {
        [decoder.0.mimeType, decoder.1.mimeType]
    }
    func decodeMIMETypeIfSupported(
        _ mimeType: MIMEType,
        from buffer: inout ByteBuffer
    ) throws -> Data? {
        switch mimeType {
        case decoder.0.mimeType:
            return try decoder.0.decode(from: &buffer)
        case decoder.1.mimeType:
            return try decoder.1.decode(from: &buffer)
        default:
            return nil
        }
    }
}

struct MultiDataDecoderTuple3<A, B, C>: MultiDataDecoderProtocol where
A: DataDecoderProtocol,
B: DataDecoderProtocol,
C: DataDecoderProtocol,
A.Data == B.Data,
A.Data == C.Data{
    typealias Data = A.Data
    let decoder: (A, B, C)
    var supportedMIMETypes: [MIMEType] {
        [decoder.0.mimeType, decoder.1.mimeType, decoder.2.mimeType]
    }
    func decodeMIMETypeIfSupported(
        _ mimeType: MIMEType,
        from buffer: inout ByteBuffer
    ) throws -> Data? {
        switch mimeType {
        case decoder.0.mimeType:
            return try decoder.0.decode(from: &buffer)
        case decoder.1.mimeType:
            return try decoder.1.decode(from: &buffer)
        case decoder.2.mimeType:
            return try decoder.2.decode(from: &buffer)
        default:
            return nil
        }
    }
}

@resultBuilder
enum MultiDataDecoderBuilder {
    static func buildBlock<Decoder>(
        _ decoder: Decoder
    ) -> Decoder where Decoder: MultiDataDecoderProtocol {
        decoder
    }
    static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> MultiDataDecoderTuple2<A, B> {
        .init(decoder: (a, b))
    }
    static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> MultiDataDecoderTuple3<A, B, C> {
        .init(decoder: (a, b, c))
    }
}


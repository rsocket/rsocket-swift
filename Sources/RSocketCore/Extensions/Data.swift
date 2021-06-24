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

public protocol DataEncoderProtocol: MultiDataEncoderProtocol {
    associatedtype Data
    var mimeType: MIMEType { get }
    func encode(_ data: Data, into buffer: inout ByteBuffer) throws
}

extension DataEncoderProtocol {
    public func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool {
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

public protocol DataDecoderProtocol: MultiDataDecoderProtocol {
    associatedtype Data
    var mimeType: MIMEType { get }
    func decode(from buffer: inout ByteBuffer) throws -> Data
}

extension DataDecoderProtocol {
    public var supportedMIMETypes: [MIMEType] { [mimeType] }
    public func decodeMIMETypeIfSupported(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data? {
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

public struct JSONDataDecoder<Data: Decodable>: DataDecoderProtocol {
    let decoder: JSONDecoder
    public var mimeType: MIMEType { .json }
    public init(type: Data.Type = Data.self, decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }
    public func decode(from buffer: inout ByteBuffer) throws -> Data {
        try decoder.decode(Data.self, from: buffer)
    }
}

public struct JSONDataEncoder<Data: Encodable>: DataEncoderProtocol {
    let encoder: JSONEncoder
    public var mimeType: MIMEType { .json }
    public init(type: Data.Type = Data.self, encoder: JSONEncoder = .init()) {
        self.encoder = encoder
    }
    public func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
        try encoder.encode(data, into: &buffer)
    }
}

public enum DataEncoders {}

extension DataEncoders {
    public struct Map<Encoder: DataEncoderProtocol, Data>: DataEncoderProtocol {
        let encoder: Encoder
        let transform: (Data) -> Encoder.Data
        public var mimeType: MIMEType { .json }
        public func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
            try encoder.encode(transform(data), into: &buffer)
        }
    }
    public struct TryMap<Encoder: DataEncoderProtocol, Data>: DataEncoderProtocol {
        let encoder: Encoder
        let transform: (Data) throws -> Encoder.Data
        public var mimeType: MIMEType { .json }
        public func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
            try encoder.encode(try transform(data), into: &buffer)
        }
    }
}

public extension DataEncoderProtocol {
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

public enum DataDecoders { }
    
public extension DataDecoders {
    struct Map<Decoder: DataDecoderProtocol, Data>: DataDecoderProtocol {
        let decoder: Decoder
        let transform: (Decoder.Data) -> Data
        public var mimeType: MIMEType { decoder.mimeType }
        public func decode(from buffer: inout ByteBuffer) throws -> Data {
            transform(try decoder.decode(from: &buffer))
        }
    }
    struct TryMap<Decoder: DataDecoderProtocol, Data>: DataDecoderProtocol {
        let decoder: Decoder
        let transform: (Decoder.Data) throws -> Data
        public var mimeType: MIMEType { decoder.mimeType }
        public func decode(from buffer: inout ByteBuffer) throws -> Data {
            try transform(try decoder.decode(from: &buffer))
        }
    }
}

public extension DataDecoderProtocol {
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

public protocol MultiDataEncoderProtocol {
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

public struct MultiDataEncoderTuple2<A, B>: MultiDataEncoderProtocol where
A: DataEncoderProtocol,
B: DataEncoderProtocol,
A.Data == B.Data
{
    public typealias Data = A.Data
    let encoder: (A, B)
    public func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool {
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

public struct MultiDataEncoderTuple3<A, B, C>: MultiDataEncoderProtocol where
A: DataEncoderProtocol,
B: DataEncoderProtocol,
C: DataEncoderProtocol,
A.Data == B.Data,
A.Data == C.Data
{
    public typealias Data = A.Data
    let encoder: (A, B, C)
    public func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool {
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
public enum MultiDataEncoderBuilder {
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

public protocol MultiDataDecoderProtocol {
    associatedtype Data
    var supportedMIMETypes: [MIMEType] { get }
    func decodeMIMETypeIfSupported(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data?
}

extension MultiDataDecoderProtocol {
    func decodeMIMEType(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data {
        guard let data = try decodeMIMETypeIfSupported(mimeType, from: &buffer) else {
            throw Error.invalid(message: "\(mimeType) not supported")
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

public struct MultiDataDecoderTuple2<A, B>: MultiDataDecoderProtocol where
A: DataDecoderProtocol,
B: DataDecoderProtocol,
A.Data == B.Data {
    public typealias Data = A.Data
    let decoder: (A, B)
    public var supportedMIMETypes: [MIMEType] {
        [decoder.0.mimeType, decoder.1.mimeType]
    }
    public func decodeMIMETypeIfSupported(
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

public struct MultiDataDecoderTuple3<A, B, C>: MultiDataDecoderProtocol where
A: DataDecoderProtocol,
B: DataDecoderProtocol,
C: DataDecoderProtocol,
A.Data == B.Data,
A.Data == C.Data{
    public typealias Data = A.Data
    let decoder: (A, B, C)
    public var supportedMIMETypes: [MIMEType] {
        [decoder.0.mimeType, decoder.1.mimeType, decoder.2.mimeType]
    }
    public func decodeMIMETypeIfSupported(
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
public enum MultiDataDecoderBuilder {
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


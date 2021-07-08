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

public protocol MultiDataDecoderProtocol {
    associatedtype Data
    var supportedMIMETypes: [MIMEType] { get }
    func decodeMIMETypeIfSupported(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data?
}

extension MultiDataDecoderProtocol {
    @inlinable
    func decodeMIMEType(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data {
        guard let data = try decodeMIMETypeIfSupported(mimeType, from: &buffer) else {
            throw Error.invalid(message: "\(mimeType) not supported")
        }
        return data
    }
}

extension MultiDataDecoderProtocol {
    @inlinable
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
    
    @usableFromInline
    internal let decoder: (A, B)
    
    @inlinable
    public var supportedMIMETypes: [MIMEType] {
        [decoder.0.mimeType, decoder.1.mimeType]
    }
    
    @inlinable
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
    
    @usableFromInline
    internal let decoder: (A, B, C)
    
    @inlinable
    public var supportedMIMETypes: [MIMEType] {
        [decoder.0.mimeType, decoder.1.mimeType, decoder.2.mimeType]
    }
    
    @inlinable
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
    public static func buildBlock<Decoder>(
        _ decoder: Decoder
    ) -> Decoder where Decoder: MultiDataDecoderProtocol {
        decoder
    }
    public static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> MultiDataDecoderTuple2<A, B> {
        .init(decoder: (a, b))
    }
    public static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> MultiDataDecoderTuple3<A, B, C> {
        .init(decoder: (a, b, c))
    }
}

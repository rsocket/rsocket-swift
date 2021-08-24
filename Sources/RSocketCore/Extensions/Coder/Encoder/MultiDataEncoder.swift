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
import NIOCore
import NIOFoundationCompat

public protocol MultiDataEncoderProtocol {
    associatedtype Data
    /// tries to encode `data` as `mimeType`.
    /// - Returns: true if it `mimeType` is a supported encoding and encoding was successful
    func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool
}

extension MultiDataEncoderProtocol {
    @inlinable
    internal func encode(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws {
        guard try encodeIfSupported(data, as: mimeType, into: &buffer) else {
            throw Error.invalid(message: "could not encode data as \(mimeType)")
        }
    }
}

extension MultiDataEncoderProtocol {
    @inlinable
    internal func encode(_ data: Data, as mimeType: MIMEType) throws -> Foundation.Data {
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
    @usableFromInline
    internal let encoder: (A, B)
    
    @inlinable
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
    
    @usableFromInline
    internal let encoder: (A, B, C)
    
    @inlinable
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
    public static func buildBlock<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: MultiDataEncoderProtocol {
        encoder
    }
    public static func buildBlock<A, B>(
        _ a: A,
        _ b: B
    ) -> MultiDataEncoderTuple2<A, B> {
        .init(encoder: (a, b))
    }
    public static func buildBlock<A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> MultiDataEncoderTuple3<A, B, C> {
        .init(encoder: (a, b, c))
    }
    public static func buildLimitedAvailability<T>(_ component: T) -> T {
        component
    }
    public static func buildEither<T>(first component: T) -> T {
        component
    }
    public static func buildEither<T>(second component: T) -> T {
        component
    }
}

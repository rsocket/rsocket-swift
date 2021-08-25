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

public protocol DataEncoderProtocol: MultiDataEncoderProtocol {
    associatedtype Data
    var mimeType: MIMEType { get }
    func encode(_ data: Data, into buffer: inout ByteBuffer) throws
}

extension DataEncoderProtocol {
    @inlinable
    public func encodeIfSupported(_ data: Data, as mimeType: MIMEType, into buffer: inout ByteBuffer) throws -> Bool {
        guard mimeType == self.mimeType else { return false }
        try encode(data, into: &buffer)
        return true
    }
}

extension DataEncoderProtocol {
    @usableFromInline
    func encode(_ data: Data) throws -> ByteBuffer {
        var buffer = ByteBuffer()
        try self.encode(data, into: &buffer)
        return buffer
    }
}

// MARK: - Data Encoders

public enum DataEncoders {}

extension DataEncoders {
    public struct Map<Encoder: DataEncoderProtocol, Data>: DataEncoderProtocol {
        @usableFromInline
        internal let encoder: Encoder
        
        @usableFromInline
        internal let transform: (Data) -> Encoder.Data
        
        @inlinable
        public var mimeType: MIMEType { encoder.mimeType }
        
        @usableFromInline
        internal init(encoder: Encoder, transform: @escaping (Data) -> Encoder.Data) {
            self.encoder = encoder
            self.transform = transform
        }
        
        @inlinable
        public func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
            try encoder.encode(transform(data), into: &buffer)
        }
    }
}

extension DataEncoderProtocol {
    @inlinable
    public func map<NewData>(
        _ transform: @escaping (NewData) -> Data
    ) -> DataEncoders.Map<Self, NewData> {
        .init(encoder: self, transform: transform)
    }
}  


extension DataEncoders {
    public struct TryMap<Encoder: DataEncoderProtocol, Data>: DataEncoderProtocol {
        @usableFromInline
        internal let encoder: Encoder
        
        @usableFromInline
        internal let transform: (Data) throws -> Encoder.Data
        
        @inlinable
        public var mimeType: MIMEType { encoder.mimeType }
        
        @usableFromInline
        internal init(encoder: Encoder, transform: @escaping (Data) throws -> Encoder.Data) {
            self.encoder = encoder
            self.transform = transform
        }
        
        @inlinable
        public func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
            try encoder.encode(try transform(data), into: &buffer)
        }
    }
}

extension DataEncoderProtocol {
    @inlinable
    public func tryMap<NewData>(
        _ transform: @escaping (NewData) throws -> Data
    ) -> DataEncoders.TryMap<Self, NewData> {
        .init(encoder: self, transform: transform)
    }
}

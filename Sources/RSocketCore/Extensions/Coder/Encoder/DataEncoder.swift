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

public protocol DataDecoderProtocol: MultiDataDecoderProtocol {
    associatedtype Data
    var mimeType: MIMEType { get }
    func decode(from buffer: inout ByteBuffer) throws -> Data
}

extension DataDecoderProtocol {
    @inlinable
    public var supportedMIMETypes: [MIMEType] { [mimeType] }
    
    @inlinable
    public func decodeMIMETypeIfSupported(_ mimeType: MIMEType, from buffer: inout ByteBuffer) throws -> Data? {
        guard mimeType == self.mimeType else { return nil }
        return try decode(from: &buffer)
    }
}

// MARK: - Data Decoders

public enum DataDecoders { }
    
extension DataDecoders {
    public struct Map<Decoder: DataDecoderProtocol, Data>: DataDecoderProtocol {
        @usableFromInline
        internal let decoder: Decoder
        
        @usableFromInline
        internal let transform: (Decoder.Data) -> Data
        
        @inlinable
        public var mimeType: MIMEType { decoder.mimeType }
        
        @usableFromInline
        internal init(decoder: Decoder, transform: @escaping (Decoder.Data) -> Data) {
            self.decoder = decoder
            self.transform = transform
        }
        
        @inlinable
        public func decode(from buffer: inout ByteBuffer) throws -> Data {
            transform(try decoder.decode(from: &buffer))
        }
    }
}

extension DataDecoderProtocol {
    @inlinable
    public func map<NewData>(
        _ transform: @escaping (Data) -> NewData
    ) -> DataDecoders.Map<Self, NewData> {
        .init(decoder: self, transform: transform)
    }
}


extension DataDecoders {
    public struct TryMap<Decoder: DataDecoderProtocol, Data>: DataDecoderProtocol {
        @usableFromInline
        internal let decoder: Decoder
        
        @usableFromInline
        internal let transform: (Decoder.Data) throws -> Data
        
        @inlinable
        public var mimeType: MIMEType { decoder.mimeType }
        
        @usableFromInline
        internal init(decoder: Decoder, transform: @escaping (Decoder.Data) throws -> Data) {
            self.decoder = decoder
            self.transform = transform
        }
        
        @inlinable
        public func decode(from buffer: inout ByteBuffer) throws -> Data {
            try transform(try decoder.decode(from: &buffer))
        }
    }
}

extension DataDecoderProtocol {
    @inlinable
    public func tryMap<NewData>(
        _ transform: @escaping (Data) throws -> NewData
    ) -> DataDecoders.TryMap<Self, NewData> {
        .init(decoder: self, transform: transform)
    }
}


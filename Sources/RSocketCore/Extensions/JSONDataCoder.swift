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

public struct JSONDataDecoder<Data: Decodable>: DataDecoderProtocol {
    @usableFromInline
    internal let decoder: JSONDecoder
    
    @inlinable
    public var mimeType: MIMEType { .applicationJson }
    
    @inlinable
    public init(type: Data.Type = Data.self, decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }
    
    @inlinable
    public func decode(from buffer: inout ByteBuffer) throws -> Data {
        try decoder.decode(Data.self, from: buffer)
    }
}

public struct JSONDataEncoder<Data: Encodable>: DataEncoderProtocol {
    @usableFromInline
    internal let encoder: JSONEncoder
    
    @inlinable
    public var mimeType: MIMEType { .applicationJson }
    
    @inlinable
    public init(type: Data.Type = Data.self, encoder: JSONEncoder = .init()) {
        self.encoder = encoder
    }
    
    @inlinable
    public func encode(_ data: Data, into buffer: inout ByteBuffer) throws {
        try encoder.encode(data, into: &buffer)
    }
}

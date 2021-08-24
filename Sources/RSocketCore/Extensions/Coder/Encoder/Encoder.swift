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

import NIOCore

public protocol EncoderProtocol {
    associatedtype Metadata
    associatedtype Data
    mutating func encode(
        metadata: Metadata,
        data: Data,
        encoding: ConnectionEncoding
    ) throws -> Payload
}

public struct Encoder: EncoderProtocol {
    @inlinable
    public init() {}
    
    @inlinable
    public func encode(metadata: ByteBuffer?, data: ByteBuffer, encoding: ConnectionEncoding) throws -> Payload {
        .init(metadata: metadata, data: data)
    }
}

/// Namespace for types conforming to the ``EncoderProtocol`` protocol
public enum Encoders {}

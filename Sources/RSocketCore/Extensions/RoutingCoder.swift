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

public struct RoutingEncoder: MetadataEncoder {
    public typealias Metadata = [String]
    
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    
    @inlinable
    public func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

public struct RoutingDecoder: MetadataDecoder {
    public typealias Metadata = [String]
    
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    
    @inlinable
    public func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == RoutingEncoder {
    public static var routing: Self { .init() }
}

extension MetadataDecoder where Self == RoutingDecoder {
    public static var routing: Self { .init() }
}

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

import NIO

public struct RoutingEncoder: MetadataEncoder {
    public typealias Metadata = RouteMetadata
    
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    
    @inlinable
    public func encode(_ metadata: RouteMetadata, into buffer: inout ByteBuffer) throws {
        for tag in metadata.tags {
            do {
                try buffer.writeLengthPrefixed(as: UInt8.self) { buffer in
                    buffer.writeString(tag)
                }
            } catch {
                throw Error.invalid(message: "route tag is longer than \(UInt8.max)")
            }
        }
    }
}

extension MetadataEncoder where Self == RoutingEncoder {
    public static var routing: Self { .init() }
}

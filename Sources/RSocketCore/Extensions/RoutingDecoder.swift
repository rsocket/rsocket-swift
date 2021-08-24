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

public struct RoutingDecoder: MetadataDecoder {
    public typealias Metadata = RouteMetadata
    
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketRoutingV0 }
    
    @inlinable
    public func decode(from buffer: inout ByteBuffer) throws -> RouteMetadata {
        var tags = [String]()
        while buffer.readableBytes != 0 {
            guard let length = buffer.readInteger(as: UInt8.self) else {
                throw Error.invalid(message: "route tag length could not be read")
            }
            guard let tag = buffer.readString(length: Int(length)) else {
                throw Error.invalid(message: "route tag could not be read")
            }
            tags.append(tag)
        }
        return .init(tags: tags)
    }
}

extension MetadataDecoder where Self == RoutingDecoder {
    public static var routing: Self { .init() }
}

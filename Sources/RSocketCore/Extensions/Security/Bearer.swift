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

public struct BearerAuthenticationDecoder: MetadataDecoder {
    @usableFromInline
    internal var authenticationDecoder: AuthenticationDecoder = .init()
    
    @inlinable
    public var mimeType: MIMEType { authenticationDecoder.mimeType }
    
    @inlinable
    public func decode(from buffer: inout ByteBuffer) throws -> String {
        fatalError("not implemented")
    }
}

extension MetadataDecoder where Self == BearerAuthenticationDecoder {
    public static var bearerAuthentication: Self { .init() }
}


public struct BearerAuthenticationEncoder: MetadataEncoder {
    @usableFromInline
    internal var authenticationEncoder: AuthenticationEncoder = .init()
    
    @inlinable
    public var mimeType: MIMEType { authenticationEncoder.mimeType }
    
    @inlinable
    public func encode(_ metadata: String, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == BearerAuthenticationEncoder {
    public static var bearerAuthentication: Self { .init() }
}

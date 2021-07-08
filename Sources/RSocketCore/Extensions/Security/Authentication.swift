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

public struct Authentication {
    public var type: AuthenticationType
    public var payload: ByteBuffer
}

public struct AuthenticationDecoder: MetadataDecoder {
    public var mimeType: MIMEType { .messageXRSocketAuthenticationV0 }
    public func decode(from buffer: inout ByteBuffer) throws -> Authentication {
        fatalError("not implemented")
    }
}

public extension MetadataDecoder where Self == AuthenticationDecoder {
    static var authentication: Self { .init() }
}

public struct AuthenticationEncoder: MetadataEncoder {
    public var mimeType: MIMEType { .messageXRSocketAuthenticationV0 }
    public func encode(_ metadata: Authentication, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

public extension MetadataEncoder where Self == AuthenticationEncoder {
    static var authentication: Self { .init() }
}

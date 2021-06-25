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

public struct AuthenticationType: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct WellKnownAuthenticationTypeCode: RawRepresentable, Hashable {
    /// rawValue is guaranteed to be between 0 and 127.
    public let rawValue: UInt8
    public init?(rawValue: UInt8) {
        guard rawValue & 0b1000_0000 == 0 else { return nil }
        self.rawValue = rawValue
    }
}
extension WellKnownAuthenticationTypeCode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt8) {
        guard let value = Self(rawValue: value) else {
            fatalError("Well Know Authentication Type Codes are only allowed to be between 0 and 127.")
        }
        self = value
    }
}

public extension AuthenticationType {
    static let simple = Self(rawValue: "simple")
    static let bearer = Self(rawValue: "bearer")
}

public extension WellKnownAuthenticationTypeCode {
    static let simple: Self = 0x00
    static let bearer: Self = 0x01
}

public extension AuthenticationType {
    static let wellKnownAuthenticationTypes: [(WellKnownAuthenticationTypeCode, AuthenticationType)] = [
        (.simple, .simple),
        (.bearer, .bearer),
    ]
}

public struct Authentication {
    public var type: AuthenticationType
    public var payload: ByteBuffer
}


public struct BearerAuthenticationDecoder: MetadataDecoder {
    var authenticationDecoder: AuthenticationDecoder = .init()
    public var mimeType: MIMEType { authenticationDecoder.mimeType }
    public func decode(from buffer: inout ByteBuffer) throws -> String {
        fatalError("not implemented")
    }
}

public extension MetadataDecoder where Self == BearerAuthenticationDecoder {
    static var bearerAuthentication: Self { .init() }
}

public struct BearerAuthenticationEncoder: MetadataEncoder {
    var authenticationEncoder: AuthenticationEncoder = .init()
    public var mimeType: MIMEType { authenticationEncoder.mimeType }
    public func encode(_ metadata: String, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

public extension MetadataEncoder where Self == BearerAuthenticationEncoder {
    static var bearerAuthentication: Self { .init() }
}

public struct SimpleAuthentication {
    public var username: String
    public var password: String
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct SimpleAuthenticationDecoder: MetadataDecoder {
    var authenticationDecoder: AuthenticationDecoder = .init()
    public var mimeType: MIMEType { authenticationDecoder.mimeType }
    public func decode(from buffer: inout ByteBuffer) throws -> SimpleAuthentication {
        fatalError("not implemented")
    }
}

public extension MetadataDecoder where Self == SimpleAuthenticationDecoder {
    static var simpleAuthentication: Self { .init() }
}

public struct SimpleAuthenticationEncoder: MetadataEncoder {
    var authenticationEncoder: AuthenticationEncoder = .init()
    public var mimeType: MIMEType { authenticationEncoder.mimeType }
    public func encode(_ metadata: SimpleAuthentication, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

public extension MetadataEncoder where Self == SimpleAuthenticationEncoder {
    static var simpleAuthentication: Self { .init() }
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

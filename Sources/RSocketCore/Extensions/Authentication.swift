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

struct AuthenticationType: RawRepresentable, Hashable {
    public private(set) var rawValue: String
}

struct WellKnownAuthenticationTypeCode: RawRepresentable {
    /// rawValue is guaranteed to be between 0 and 127.
    public var rawValue: UInt8
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

extension AuthenticationType {
    static let simple = Self(rawValue: "simple")
    static let bearer = Self(rawValue: "bearer")
}

extension WellKnownAuthenticationTypeCode {
    static let simple: Self = 0x00
    static let bearer: Self = 0x01
}

extension AuthenticationType {
    static let wellKnownAuthenticationTypes: [(WellKnownAuthenticationTypeCode, AuthenticationType)] = [
        (.simple, .simple),
        (.bearer, .bearer),
    ]
}

struct Authentication {
    var type: AuthenticationType
    var payload: ByteBuffer
}


struct BearerAuthenticationDecoder: MetadataDecoder {
    var authenticationDecoder: AuthenticationDecoder = .init()
    var mimeType: MIMEType { authenticationDecoder.mimeType }
    func decode(from buffer: inout ByteBuffer) throws -> String {
        fatalError("not implemented")
    }
}

extension MetadataDecoder where Self == BearerAuthenticationDecoder {
    static var bearerAuthentication: Self { .init() }
}

struct BearerAuthenticationEncoder: MetadataEncoder {
    var authenticationEncoder: AuthenticationEncoder = .init()
    var mimeType: MIMEType { authenticationEncoder.mimeType }
    func encode(_ metadata: String, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == BearerAuthenticationEncoder {
    static var bearerAuthentication: Self { .init() }
}

struct SimpleAuthentication {
    var username: String
    var password: String
}

struct SimpleAuthenticationDecoder: MetadataDecoder {
    var authenticationDecoder: AuthenticationDecoder = .init()
    var mimeType: MIMEType { authenticationDecoder.mimeType }
    func decode(from buffer: inout ByteBuffer) throws -> SimpleAuthentication {
        fatalError("not implemented")
    }
}

extension MetadataDecoder where Self == SimpleAuthenticationDecoder {
    static var simpleAuthentication: Self { .init() }
}

struct SimpleAuthenticationEncoder: MetadataEncoder {
    var authenticationEncoder: AuthenticationEncoder = .init()
    var mimeType: MIMEType { authenticationEncoder.mimeType }
    func encode(_ metadata: SimpleAuthentication, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == SimpleAuthenticationEncoder {
    static var simpleAuthentication: Self { .init() }
}

struct AuthenticationDecoder: MetadataDecoder {
    var mimeType: MIMEType { .messageXRSocketAuthenticationV0 }
    func decode(from buffer: inout ByteBuffer) throws -> Authentication {
        fatalError("not implemented")
    }
}

extension MetadataDecoder where Self == AuthenticationDecoder {
    static var authentication: Self { .init() }
}

struct AuthenticationEncoder: MetadataEncoder {
    var mimeType: MIMEType { .messageXRSocketAuthenticationV0 }
    func encode(_ metadata: Authentication, into buffer: inout ByteBuffer) throws {
        fatalError("not implemented")
    }
}

extension MetadataEncoder where Self == AuthenticationEncoder {
    static var authentication: Self { .init() }
}

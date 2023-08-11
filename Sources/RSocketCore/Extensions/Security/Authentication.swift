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

public struct Authentication {
    public var type: AuthenticationType
    public var payload: ByteBuffer
    public init(type: AuthenticationType, payload: ByteBuffer) {
        self.type = type
        self.payload = payload
    }
}

public struct AuthenticationDecoder: MetadataDecoder {
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketAuthenticationV0 }
    
    public func decode(from buffer: inout ByteBuffer) throws -> Authentication {
        let idOrLength = buffer.readBytes(length: 1)?.withUnsafeBytes{ value -> UInt8 in
            return value.load(as: UInt8.self)
        }
        debugPrint(idOrLength! & 0x7F)
        debugPrint(idOrLength!)
        switch idOrLength! & 0x7F  {
        case WellKnownAuthenticationType.SIMPLE.identifier :
            return Authentication(type: AuthenticationType.simple,payload: buffer)
        case WellKnownAuthenticationType.BEARER.identifier:
            return Authentication(type: AuthenticationType.bearer ,payload: buffer)
        default :
            return Authentication(type: AuthenticationType(rawValue: buffer.readString(length: Int(idOrLength!)) ?? "") ,payload: buffer)
        }
       
    }
}

extension MetadataDecoder where Self == AuthenticationDecoder {
    public static var authentication: Self { .init() }
    
    //Return ID or Auth Length
    public static func isWellKnownAuthType(_  buffer : ByteBuffer) -> Bool{
        var tmp = buffer
        guard let authType = (tmp.readBytes(length: 1)?.withUnsafeBytes{ value -> UInt8 in return value.load(as: UInt8.self).bigEndian}) else{
            return false
        }
        let idOrLength = UInt8(authType & 0x7F)
        return idOrLength != authType
    }
}

public struct AuthenticationEncoder: MetadataEncoder {
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketAuthenticationV0 }
    
    @inlinable
    public func encode(_ metadata: Authentication, into buffer: inout ByteBuffer) throws {
        switch metadata.type{
        case .bearer:
            buffer.mergeByteBuffers(buffers: [ByteBuffer(integer: UInt8(WellKnownAuthenticationType.BEARER.identifier )), metadata.payload])
        case .simple:
            buffer.mergeByteBuffers(buffers: [ByteBuffer(integer: UInt8(WellKnownAuthenticationType.SIMPLE.identifier)),
                                              metadata.payload])
        default:
            try encodeCustomMetadata(customAuthType: metadata.type.rawValue, metadata: metadata.payload , into: &buffer)
        }
    }
    
    @inlinable
    public func encodeCustomMetadata(customAuthType: String, metadata: ByteBuffer , into buffer: inout ByteBuffer) throws {
        do {
            try buffer.writeLengthPrefixed(as: UInt8.self) { buffer in
                buffer.writeString(customAuthType)
            }
        } catch {
            throw Error.invalid(message: "MIME Type \(mimeType) too long to encode")
        }
        var aux = metadata
        buffer.writeBuffer(&aux)
    }
}

extension MetadataEncoder where Self == AuthenticationEncoder {
    public static var authentication: Self { .init() }
}

//
//  File.swift
//  
//
//  Created by Elyes Ben Salah on 6/2/2023.
//


import NIOCore


public struct CustomAuthenticationDecoder: MetadataDecoder {
    @usableFromInline
    internal var authenticationDecoder: AuthenticationDecoder = .init()
    
    @inlinable
    public var mimeType: MIMEType { authenticationDecoder.mimeType }
    
    
    public func decode(from buffer: inout ByteBuffer) throws -> Authentication {
        guard var slice = buffer.readLengthPrefixedSlice(as: UInt8.self),
              let customAuthType = slice.readString(length: slice.readableBytes)
        else {
            throw Error.invalid(message: "authType could not be read")
        }
        
        return .init(type: AuthenticationType(rawValue: customAuthType), payload: ByteBuffer(bytes: buffer.readBytes(length: buffer.readableBytes) ?? []))
    }
}

extension MetadataDecoder where Self == CustomAuthenticationDecoder {
    public static var customAuthentication: Self { .init() }
}


public struct CustomAuthenticationEncoder: MetadataEncoder {
    @usableFromInline
    internal var authenticationEncoder: AuthenticationEncoder = .init()
    
    @inlinable
    public var mimeType: MIMEType { authenticationEncoder.mimeType }
    
    @inlinable
    public func encode(_ metadata: Authentication , into buffer: inout ByteBuffer) throws {
        try encodeCustomMetadata(metadata, into: &buffer)
    }
    
    @inlinable
    public func encodeCustomMetadata(_ customAuth : Authentication , into buffer: inout ByteBuffer) throws {
        do {
            try buffer.writeLengthPrefixed(as: UInt8.self) { buffer in
                buffer.writeString(customAuth.type.rawValue)
            }
        } catch {
            throw Error.invalid(message: "MIME Type \(mimeType) too long to encode")
        }
        var aux = customAuth.payload
        buffer.writeBuffer(&aux)
    }
   
}

extension MetadataEncoder where Self == CustomAuthenticationEncoder {
    public static var customAuthentication: Self { .init() }
}

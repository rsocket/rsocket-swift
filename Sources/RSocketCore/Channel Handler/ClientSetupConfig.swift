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


/// This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
/// Many are registered with IANA such as CBOR.
public struct MIMEType: RawRepresentable, Hashable {
    public private(set) var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension MIMEType {
    
    /// default is currently `MIMEType.octetStream`
    static let `default` = octetStream
    
    /// application/json
    static let json = MIMEType(rawValue: "application/json")
    
    /// application/octet-stream
    static let octetStream = MIMEType(rawValue: "application/octet-stream")
    
    
    /// message/x.rsocket.routing.v0
    static let rsocketRoutingV0 = MIMEType(rawValue: "message/x.rsocket.routing.v0")
}

public struct ClientSetupConfig {
    /**
     Time (in milliseconds) between `KEEPALIVE` frames that the client will send

     Value MUST be > `0`.
     - For server-to-server connections, a reasonable time interval between client `KEEPALIVE` frames is 500ms.
     - For mobile-to-server connections, the time interval between client `KEEPALIVE` frames is often > 30,000ms.
     */
    public var timeBetweenKeepaliveFrames: Int32

    /**
     Time (in milliseconds) that a client will allow a server to not respond to a `KEEPALIVE`
     before it is assumed to be dead

     Value MUST be > `0`.
     */
    public var maxLifetime: Int32

    /**
     MIME Type for encoding of Metadata

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     */
    public var metadataEncodingMimeType: String

    /**
     MIME Type for encoding of Data

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     */
    public var dataEncodingMimeType: String

    /// Payload of this frame describing connection capabilities of the endpoint sending the Setup header
    public var payload: Payload


    /// client setup that is initially send to the server
    /// - Parameters:
    ///   - timeBetweenKeepaliveFrames: Time (in milliseconds) between `KEEPALIVE` frames that the client will send
    ///    Value MUST be > `0`.
    ///     - For server-to-server connections, a reasonable time interval between client `KEEPALIVE` frames is 500ms.
    ///     - For mobile-to-server connections, the time interval between client `KEEPALIVE` frames is often > 30,000ms.
    ///   - maxLifetime: Time (in milliseconds) that a client will allow a server to not respond to a `KEEPALIVE`
    ///     before it is assumed to be dead.
    ///
    ///     Value MUST be > `0`.
    ///   - metadataEncodingMimeType: MIME Type for encoding of Metadata
    ///
    ///     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
    ///     Many are registered with IANA such as CBOR.
    ///     Suffix rules MAY be used for handling layout.
    ///     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
    ///   - dataEncodingMimeType:MIME Type for encoding of Data
    ///
    ///     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
    ///     Many are registered with IANA such as CBOR.
    ///     Suffix rules MAY be used for handling layout.
    ///     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
    ///   - payload: Payload of the setup frame describing connection capabilities of the client
    public init(
        timeBetweenKeepaliveFrames: Int32,
        maxLifetime: Int32,
        metadataEncodingMimeType: String,
        dataEncodingMimeType: String,
        payload: Payload = .empty
    ) {
        self.timeBetweenKeepaliveFrames = timeBetweenKeepaliveFrames
        self.maxLifetime = maxLifetime
        self.metadataEncodingMimeType = metadataEncodingMimeType
        self.dataEncodingMimeType = dataEncodingMimeType
        self.payload = payload
    }
}

extension ClientSetupConfig {
    public static var defaultMobileToServer: ClientSetupConfig {
        ClientSetupConfig(
            timeBetweenKeepaliveFrames: 30_000,
            maxLifetime: 30_000,
            metadataEncodingMimeType: "application/octet-stream",
            dataEncodingMimeType: "application/octet-stream"
        )
    }

    public static var defaultServerToServer: ClientSetupConfig {
        ClientSetupConfig(
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 500,
            metadataEncodingMimeType: "application/octet-stream",
            dataEncodingMimeType: "application/octet-stream"
        )
    }
}

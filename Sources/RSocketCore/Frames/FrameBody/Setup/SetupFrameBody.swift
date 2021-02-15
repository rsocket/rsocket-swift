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

/**
 The `SETUP` frame is sent by the client to inform the server of the parameters under which it desires to operate

 The usage and message sequence used is shown in Connection Establishment.
 */
internal struct SetupFrameBody {
    /// If the connection should honor `LEASE`
    internal let honorsLease: Bool

    /// Major version number of the protocol
    internal let majorVersion: UInt16

    /// Minor version number of the protocol
    internal let minorVersion: UInt16

    /**
     Time (in milliseconds) between `KEEPALIVE` frames that the client will send

     Value MUST be > `0`.
     - For server-to-server connections, a reasonable time interval between client `KEEPALIVE` frames is 500ms.
     - For mobile-to-server connections, the time interval between client `KEEPALIVE` frames is often > 30,000ms.
     */
    internal let timeBetweenKeepaliveFrames: Int32

    /**
     Time (in milliseconds) that a client will allow a server to not respond to a `KEEPALIVE`
     before it is assumed to be dead

     Value MUST be > `0`.
     */
    internal let maxLifetime: Int32

    /// Token used for client resume identification
    internal let resumeIdentificationToken: Data?

    /**
     MIME Type for encoding of Metadata

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     The string MUST NOT be null terminated.
     */
    internal let metadataEncodingMimeType: String

    /**
     MIME Type for encoding of Data

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     The string MUST NOT be null terminated.
     */
    internal let dataEncodingMimeType: String

    /// Payload of this frame describing connection capabilities of the endpoint sending the Setup header
    internal let payload: Payload
}

extension SetupFrameBody {
    func header() -> FrameHeader {
        var flags = FrameFlags()
        if payload.metadata != nil {
            flags.insert(.metadata)
        }
        if resumeIdentificationToken != nil {
            flags.insert(.setupResume)
        }
        if honorsLease {
            flags.insert(.setupLease)
        }
        return FrameHeader(streamId: .connection, type: .setup, flags: flags)
    }
}

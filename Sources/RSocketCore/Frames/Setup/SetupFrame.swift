import Foundation

/**
 The `SETUP` frame is sent by the client to inform the server of the parameters under which it desires to operate

 The usage and message sequence used is shown in Connection Establishment.
 */
public struct SetupFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// Major version number of the protocol
    public let majorVersion: UInt16

    /// Minor version number of the protocol
    public let minorVersion: UInt16

    /**
     Time (in milliseconds) between `KEEPALIVE` frames that the client will send

     Value MUST be > `0`.
     - For server-to-server connections, a reasonable time interval between client `KEEPALIVE` frames is 500ms.
     - For mobile-to-server connections, the time interval between client `KEEPALIVE` frames is often > 30,000ms.
     */
    public let timeBetweenKeepaliveFrames: Int32

    /**
     Time (in milliseconds) that a client will allow a server to not respond to a `KEEPALIVE`
     before it is assumed to be dead

     Value MUST be > `0`.
     */
    public let maxLifetime: Int32

    /// Token used for client resume identification
    public let resumeIdentificationToken: Data?

    /**
     MIME Type for encoding of Metadata

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     The string MUST NOT be null terminated.
     */
    public let metadataEncodingMimeType: String

    /**
     MIME Type for encoding of Data

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     The string MUST NOT be null terminated.
     */
    public let dataEncodingMimeType: String

    /// Optional metadata of this frame
    public let metadata: Data?

    /// Payload of this frame describing connection capabilities of the endpoint sending the Setup header
    public let payload: Data

    public init(
        header: FrameHeader,
        majorVersion: UInt16,
        minorVersion: UInt16,
        timeBetweenKeepaliveFrames: Int32,
        maxLifetime: Int32,
        resumeIdentificationToken: Data?,
        metadataEncodingMimeType: String,
        dataEncodingMimeType: String,
        metadata: Data?,
        payload: Data
    ) {
        self.header = header
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.timeBetweenKeepaliveFrames = timeBetweenKeepaliveFrames
        self.maxLifetime = maxLifetime
        self.resumeIdentificationToken = resumeIdentificationToken
        self.metadataEncodingMimeType = metadataEncodingMimeType
        self.dataEncodingMimeType = dataEncodingMimeType
        self.metadata = metadata
        self.payload = payload
    }
}

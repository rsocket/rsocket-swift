import Foundation

/**
 The `RESUME` frame is sent by the client to resume the connection

 It replaces the `SETUP` frame.
 */
public struct ResumeFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// Major version number of the protocol
    public let majorVersion: UInt16

    /// Minor version number of the protocol
    public let minorVersion: UInt16

    /// Token used for client resume identification
    public let resumeIdentificationToken: Data

    /// The last implied position the client received from the server
    public let lastReceivedServerPosition: Int64

    /// The earliest position that the client can rewind back to prior to resending frames
    public let firstAvailableClientPosition: Int64

    public init(
        header: FrameHeader,
        majorVersion: UInt16,
        minorVersion: UInt16,
        resumeIdentificationToken: Data,
        lastReceivedServerPosition: Int64,
        firstAvailableClientPosition: Int64
    ) {
        self.header = header
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.resumeIdentificationToken = resumeIdentificationToken
        self.lastReceivedServerPosition = lastReceivedServerPosition
        self.firstAvailableClientPosition = firstAvailableClientPosition
    }
}

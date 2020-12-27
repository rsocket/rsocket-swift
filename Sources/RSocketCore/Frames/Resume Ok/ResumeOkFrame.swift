import Foundation

/// The `RESUME_OK` frame is sent in response to a `RESUME` if resuming operation possible
public struct ResumeOkFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// The last implied position the server received from the client
    public let lastReceivedClientPosition: Int64

    public init(
        header: FrameHeader,
        lastReceivedClientPosition: Int64
    ) {
        self.header = header
        self.lastReceivedClientPosition = lastReceivedClientPosition
    }
}

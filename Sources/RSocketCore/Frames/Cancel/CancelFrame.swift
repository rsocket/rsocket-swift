import Foundation

/// A cancel frame indicates the cancellation of an outstanding request
public struct CancelFrame {
    /// The header of this frame
    public let header: FrameHeader

    public init(header: FrameHeader) {
        self.header = header
    }
}

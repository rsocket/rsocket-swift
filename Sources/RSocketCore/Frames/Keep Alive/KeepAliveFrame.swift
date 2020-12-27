import Foundation

/// Indicates to the receiver that the sender is alive
public struct KeepAliveFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     Resume Last Received Position

     Value MUST be > `0`. (optional. Set to all `0`s when not supported.)
     */
    public let lastReceivedPosition: Int64

    /// Data attached to a `KEEPALIVE`
    public let data: Data

    public init(
        header: FrameHeader,
        lastReceivedPosition: Int64,
        data: Data
    ) {
        self.header = header
        self.lastReceivedPosition = lastReceivedPosition
        self.data = data
    }
}

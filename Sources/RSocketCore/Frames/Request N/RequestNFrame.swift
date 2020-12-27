import Foundation

/// Request `N` more items with Reactive Streams semantics
public struct RequestNFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     The number of items to request

     Value MUST be > `0`.
     */
    public let requestN: Int32

    public init(
        header: FrameHeader,
        requestN: Int32
    ) {
        self.header = header
        self.requestN = requestN
    }
}

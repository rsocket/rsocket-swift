import Foundation

public struct FrameHeader {
    public static let lengthInBytes = 6

    /// The id of the corresponding stream
    public let streamId: Int32

    /// The type of the frame
    public let type: FrameType

    /// The flags that are set on the frame
    public let flags: FrameFlags

    public init(
        streamId: Int32,
        type: FrameType,
        flags: FrameFlags
    ) {
        self.streamId = streamId
        self.type = type
        self.flags = flags
    }
}

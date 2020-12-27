import Foundation

/**
 Payload on a stream

 For example, response to a request, or message on a channel.
 */
public struct PayloadFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// Optional metadata of this frame
    public let metadata: Data?

    /// Payload for Reactive Streams `onNext`
    public let payload: Data

    public init(
        header: FrameHeader,
        metadata: Data? = nil,
        payload: Data
    ) {
        self.header = header
        self.metadata = metadata
        self.payload = payload
    }
}

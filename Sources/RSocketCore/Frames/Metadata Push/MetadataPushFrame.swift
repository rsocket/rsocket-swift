import Foundation

/// A Metadata Push frame can be used to send asynchronous metadata notifications from a Requester or Responder to its peer
public struct MetadataPushFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// Metadata of this frame
    public let metadata: Data

    public init(
        header: FrameHeader,
        metadata: Data
    ) {
        self.header = header
        self.metadata = metadata
    }
}

import Foundation

/// A single one-way message
public struct RequestFireAndForgetFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// Optional metadata of this frame
    public let metadata: Data?

    /// Identification of the service being requested along with parameters for the request
    public let payload: Data

    public init(
        header: FrameHeader,
        metadata: Data?,
        payload: Data
    ) {
        self.header = header
        self.metadata = metadata
        self.payload = payload
    }
}

import Foundation

/// Request a completable stream
public struct RequestStreamFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     The initial number of items to request

     Value MUST be > `0`.
     */
    public let initialRequestN: Int32

    /// Optional metadata of this frame
    public let metadata: Data?

    /// Identification of the service being requested along with parameters for the request
    public let payload: Data

    public init(
        header: FrameHeader,
        initialRequestN: Int32,
        metadata: Data?,
        payload: Data
    ) {
        self.header = header
        self.initialRequestN = initialRequestN
        self.metadata = metadata
        self.payload = payload
    }
}

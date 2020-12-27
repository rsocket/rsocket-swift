import Foundation

/// Used To extend more frame types as well as extensions
public struct ExtensionFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     Extended type information

     Value MUST be > `0`.
     */
    public let extendedType: Int32

    /// Optional metadata of this frame
    public let metadata: Data?

    /// The payload for the extended type
    public let payload: Data

    public init(
        header: FrameHeader,
        extendedType: Int32,
        metadata: Data?,
        payload: Data
    ) {
        self.header = header
        self.extendedType = extendedType
        self.metadata = metadata
        self.payload = payload
    }
}

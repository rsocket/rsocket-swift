import Foundation

/**
 Error frames are used for errors on individual requests/streams as well
 as connection errors and in response to `SETUP` frames.
 */
public struct ErrorFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// The type of the error
    public let errorCode: ErrorCode

    /// Error information
    public let errorData: String

    public init(
        header: FrameHeader,
        errorCode: ErrorCode,
        errorData: String
    ) {
        self.header = header
        self.errorCode = errorCode
        self.errorData = errorData
    }
}

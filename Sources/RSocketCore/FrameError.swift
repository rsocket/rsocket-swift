import Foundation

public enum FrameError: Error {
    /// The given data is too small and can not be parsed
    case tooSmall

    /// The given string contains invalid characters which can not be represented in the required encoding
    case stringContainsInvalidCharacters

    /// The metadata is too big and can't be encoded
    case metadataTooBig

    /// An error occurred while reading/writing the frame header
    case header(FrameHeaderError)

    /// An error occurred while reading/writing the `SETUP` frame
    case setup(SetupFrameError)

    /// An error occurred while reading/writing the `ERROR` frame
    case error(ErrorFrameError)

    /// An error occurred while reading/writing the `LEASE` frame
    case lease(LeaseFrameError)

    /// An error occurred while reading/writing the `KEEPALIVE` frame
    case keepAlive(KeepAliveFrameError)

    /// An error occurred while reading/writing the `REQUEST_STREAM` frame
    case requestStream(RequestStreamFrameError)

    /// An error occurred while reading/writing the `REQUEST_CHANNEL` frame
    case requestChannel(RequestChannelFrameError)

    /// An error occurred while reading/writing the `REQUEST_N` frame
    case requestN(RequestNFrameError)

    /// An error occurred while reading/writing the `METADATA_PUSH` frame
    case metadataPush(MetadataPushFrameError)

    /// An error occurred while reading/writing the `EXT` frame
    case `extension`(ExtensionFrameError)

    /// An error occurred while reading/writing the `RESUME` frame
    case resume(ResumeFrameError)

    /// An error occurred while reading/writing the `RESUME_OK` frame
    case resumeOk(ResumeOkFrameError)
}

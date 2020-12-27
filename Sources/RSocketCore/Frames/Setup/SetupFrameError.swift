import Foundation

public enum SetupFrameError: Error {
    case streamIdIsNotZero
    case timeBetweenKeepaliveFramesIsNotPositive
    case maxLifetimeIsNotPositive
    case resumeIdentificationTokenTooBig
    case metadataEncodingMimeTypeTooBig
    case dataEncodingMimeTypeTooBig
    case metadataEncodingMimeTypeContainsInvalidCharacters
    case dataEncodingMimeTypeContainsInvalidCharacters
}

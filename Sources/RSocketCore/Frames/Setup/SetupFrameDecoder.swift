import Foundation
import NIO
import NIOFoundationCompat

public struct SetupFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> SetupFrame {
        guard let majorVersion: UInt16 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let minorVersion: UInt16 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let timeBetweenKeepaliveFrames: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let maxLifetime: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let resumeIdentificationToken: Data?
        if header.flags.contains(.setupResume) {
            guard let resumeTokenLength: UInt16 = buffer.readInteger() else {
                throw FrameError.tooSmall
            }
            guard let resumeTokenData = buffer.readData(length: Int(resumeTokenLength)) else {
                throw FrameError.tooSmall
            }
            resumeIdentificationToken = resumeTokenData
        } else {
            resumeIdentificationToken = nil
        }
        guard let metadataEncodingMimeTypeLength: UInt8 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard metadataEncodingMimeTypeLength <= buffer.readableBytes else {
            throw FrameError.tooSmall
        }
        guard let metadataEncodingMimeType = buffer.readString(length: Int(metadataEncodingMimeTypeLength), encoding: .ascii) else {
            throw FrameError.stringContainsInvalidCharacters
        }
        guard let dataEncodingMimeTypeLength: UInt8 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard dataEncodingMimeTypeLength <= buffer.readableBytes else {
            throw FrameError.tooSmall
        }
        guard let dataEncodingMimeType = buffer.readString(length: Int(dataEncodingMimeTypeLength), encoding: .ascii) else {
            throw FrameError.stringContainsInvalidCharacters
        }
        let metadata: Data?
        if header.flags.contains(.metadata) {
            guard let metadataLengthBytes = buffer.readBytes(length: FrameConstants.metadataLengthFieldLengthInBytes) else {
                throw FrameError.tooSmall
            }
            let metadataLength = Int(bytes: metadataLengthBytes)
            guard let metadataData = buffer.readData(length: metadataLength) else {
                throw FrameError.tooSmall
            }
            metadata = metadataData
        } else {
            metadata = nil
        }
        let payload: Data
        if buffer.readableBytes > 0 {
            payload = buffer.readData(length: buffer.readableBytes) ?? Data()
        } else {
            payload = Data()
        }
        return SetupFrame(
            header: header,
            majorVersion: majorVersion,
            minorVersion: minorVersion,
            timeBetweenKeepaliveFrames: timeBetweenKeepaliveFrames,
            maxLifetime: maxLifetime,
            resumeIdentificationToken: resumeIdentificationToken,
            metadataEncodingMimeType: metadataEncodingMimeType,
            dataEncodingMimeType: dataEncodingMimeType,
            metadata: metadata,
            payload: payload
        )
    }
}

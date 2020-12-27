import BinaryKit
import Foundation

public struct SetupFrameEncoder: FrameEncoder {
    public func encode(frame: SetupFrame) throws -> Data {
        var binary = Binary()
        
        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))

        binary.writeInt(frame.majorVersion)

        binary.writeInt(frame.minorVersion)

        binary.writeInt(frame.timeBetweenKeepaliveFrames)

        binary.writeInt(frame.maxLifetime)

        if let token = frame.resumeIdentificationToken {
            guard token.count <= UInt16.max else {
                throw FrameError.setup(.resumeIdentificationTokenTooBig)
            }
            binary.writeInt(UInt16(token.count))
            binary.writeBytes(Array(token))
        }

        guard let metadataEncodingMimeTypeAsciiData = frame.metadataEncodingMimeType.data(using: .ascii) else {
            throw FrameError.setup(.metadataEncodingMimeTypeContainsInvalidCharacters)
        }
        guard metadataEncodingMimeTypeAsciiData.count <= UInt8.max else {
            throw FrameError.setup(.metadataEncodingMimeTypeTooBig)
        }
        binary.writeInt(UInt8(metadataEncodingMimeTypeAsciiData.count))
        binary.writeBytes(Array(metadataEncodingMimeTypeAsciiData))

        guard let dataEncodingMimeTypeAsciiData = frame.dataEncodingMimeType.data(using: .ascii) else {
            throw FrameError.setup(.dataEncodingMimeTypeContainsInvalidCharacters)
        }
        guard dataEncodingMimeTypeAsciiData.count <= UInt8.max else {
            throw FrameError.setup(.dataEncodingMimeTypeTooBig)
        }
        binary.writeInt(UInt8(dataEncodingMimeTypeAsciiData.count))
        binary.writeBytes(Array(dataEncodingMimeTypeAsciiData))

        if let metadata = frame.metadata {
            guard metadata.count <= FrameConstants.metadataMaximumLength else {
                throw FrameError.metadataTooBig
            }
            let metadataLengthBits = UInt32(metadata.count).bits.suffix(FrameConstants.metadataLengthFieldLengthInBytes)
            for bit in metadataLengthBits {
                binary.writeBit(bit: bit)
            }
            binary.writeBytes(Array(metadata))
        }

        binary.writeBytes(Array(frame.payload))
        
        return Data(binary.bytesStore)
    }
}

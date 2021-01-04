import Foundation
import NIO
import NIOFoundationCompat

public struct SetupFrameEncoder: FrameEncoder {
    public func encode(frame: SetupFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.majorVersion)
        buffer.writeInteger(frame.minorVersion)
        buffer.writeInteger(frame.timeBetweenKeepaliveFrames)
        buffer.writeInteger(frame.maxLifetime)
        if let token = frame.resumeIdentificationToken {
            guard token.count <= UInt16.max else {
                throw FrameError.setup(.resumeIdentificationTokenTooBig)
            }
            buffer.writeInteger(UInt16(token.count))
            buffer.writeData(token)
        }
        guard let metadataEncodingMimeTypeAsciiData = frame.metadataEncodingMimeType.data(using: .ascii) else {
            throw FrameError.setup(.metadataEncodingMimeTypeContainsInvalidCharacters)
        }
        guard metadataEncodingMimeTypeAsciiData.count <= UInt8.max else {
            throw FrameError.setup(.metadataEncodingMimeTypeTooBig)
        }
        buffer.writeInteger(UInt8(metadataEncodingMimeTypeAsciiData.count))
        buffer.writeData(metadataEncodingMimeTypeAsciiData)
        guard let dataEncodingMimeTypeAsciiData = frame.dataEncodingMimeType.data(using: .ascii) else {
            throw FrameError.setup(.dataEncodingMimeTypeContainsInvalidCharacters)
        }
        guard dataEncodingMimeTypeAsciiData.count <= UInt8.max else {
            throw FrameError.setup(.dataEncodingMimeTypeTooBig)
        }
        buffer.writeInteger(UInt8(dataEncodingMimeTypeAsciiData.count))
        buffer.writeData(dataEncodingMimeTypeAsciiData)
        if let metadata = frame.metadata {
            guard metadata.count <= FrameConstants.metadataMaximumLength else {
                throw FrameError.metadataTooBig
            }
            let metadataLengthBytes = UInt32(metadata.count).bytes.suffix(FrameConstants.metadataLengthFieldLengthInBytes)
            buffer.writeBytes(metadataLengthBytes)
            buffer.writeData(metadata)
        }
        buffer.writeData(frame.payload)
        return buffer
    }
}

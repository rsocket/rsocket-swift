import BinaryKit
import Foundation

public struct SetupFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> SetupFrame {
        let majorVersion: UInt16
        let minorVersion: UInt16
        let timeBetweenKeepaliveFrames: Int32
        let maxLifetime: Int32
        let resumeIdentificationToken: Data?
        let metadataEncodingMimeType: String
        let dataEncodingMimeType: String
        let metadata: Data?
        let payload: Data
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            majorVersion = try binary.readUInt16()

            minorVersion = try binary.readUInt16()

            timeBetweenKeepaliveFrames = try binary.readInt32()

            maxLifetime = try binary.readInt32()

            if header.flags.contains(.setupResume) {
                let resumeTokenLength = try binary.readUInt16()
                resumeIdentificationToken = Data(try binary.readBytes(Int(resumeTokenLength)))
            } else {
                resumeIdentificationToken = nil
            }

            let metadataEncodingMimeTypeLength = try binary.readUInt8()
            metadataEncodingMimeType = try binary.readString(
                quantityOfBytes: Int(metadataEncodingMimeTypeLength),
                encoding: .ascii
            )

            let dataEncodingMimeTypeLength = try binary.readUInt8()
            dataEncodingMimeType = try binary.readString(
                quantityOfBytes: Int(dataEncodingMimeTypeLength),
                encoding: .ascii
            )

            if header.flags.contains(.metadata) {
                let metadataLength = try binary.readBits(FrameConstants.metadataLengthFieldLengthInBytes)
                metadata = Data(try binary.readBytes(metadataLength))
            } else {
                metadata = nil
            }

            let remainingBytes = binary.count - binary.readBitCursor
            payload = Data(try binary.readBytes(remainingBytes))
        } catch let error as BinaryError {
            throw FrameError.binary(error)
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

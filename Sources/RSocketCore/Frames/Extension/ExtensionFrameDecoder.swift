import BinaryKit
import Foundation

public struct ExtensionFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> ExtensionFrame {
        let extendedType: Int32
        let metadata: Data?
        let payload: Data
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            extendedType = try binary.readInt32()
            
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
        return ExtensionFrame(
            header: header,
            extendedType: extendedType,
            metadata: metadata,
            payload: payload
        )
    }
}

import BinaryKit
import Foundation

public struct RequestResponseFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> RequestResponseFrame {
        let metadata: Data?
        let payload: Data
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
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
        return RequestResponseFrame(
            header: header,
            metadata: metadata,
            payload: payload
        )
    }
}

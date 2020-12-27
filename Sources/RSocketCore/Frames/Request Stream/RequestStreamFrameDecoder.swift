import BinaryKit
import Foundation

public struct RequestStreamFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> RequestStreamFrame {
        let initialRequestN: Int32
        let metadata: Data?
        let payload: Data
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            initialRequestN = try binary.readInt32()

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
        return RequestStreamFrame(
            header: header,
            initialRequestN: initialRequestN,
            metadata: metadata,
            payload: payload
        )
    }
}

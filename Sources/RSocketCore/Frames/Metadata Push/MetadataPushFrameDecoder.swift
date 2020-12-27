import BinaryKit
import Foundation

public struct MetadataPushFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> MetadataPushFrame {
        let metadata: Data
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            let remainingBytes = binary.count - binary.readBitCursor
            metadata = Data(try binary.readBytes(remainingBytes))
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return MetadataPushFrame(header: header, metadata: metadata)
    }
}

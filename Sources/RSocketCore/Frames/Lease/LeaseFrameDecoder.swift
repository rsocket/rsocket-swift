import BinaryKit
import Foundation

public struct LeaseFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> LeaseFrame {
        let timeToLive: Int32
        let numberOfRequests: Int32
        let metadata: Data?
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            timeToLive = try binary.readInt32()
            numberOfRequests = try binary.readInt32()
            if header.flags.contains(.metadata) {
                let remainingBytes = binary.count - binary.readBitCursor
                metadata = Data(try binary.readBytes(remainingBytes))
            } else {
                metadata = nil
            }
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return LeaseFrame(
            header: header,
            timeToLive: timeToLive,
            numberOfRequests: numberOfRequests,
            metadata: metadata
        )
    }
}

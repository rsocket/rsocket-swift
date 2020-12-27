import BinaryKit
import Foundation

public struct KeepAliveFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> KeepAliveFrame {
        let lastReceivedPosition: Int64
        let data: Data
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            lastReceivedPosition = try binary.readInt64()

            let remainingBytes = binary.count - binary.readBitCursor
            data = Data(try binary.readBytes(remainingBytes))
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return KeepAliveFrame(
            header: header,
            lastReceivedPosition: lastReceivedPosition,
            data: data
        )
    }
}

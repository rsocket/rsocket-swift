import BinaryKit
import Foundation

public struct ResumeOkFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> ResumeOkFrame {
        let lastReceivedClientPosition: Int64
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            lastReceivedClientPosition = try binary.readInt64()
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return ResumeOkFrame(
            header: header,
            lastReceivedClientPosition: lastReceivedClientPosition
        )
    }
}

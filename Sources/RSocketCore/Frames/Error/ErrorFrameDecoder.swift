import BinaryKit
import Foundation

public struct ErrorFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> ErrorFrame {
        let errorCode: ErrorCode
        let errorData: String
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            let codeValue = try binary.readUInt32()
            errorCode = ErrorCode(rawValue: codeValue)

            let remainingBytes = binary.count - binary.readBitCursor
            errorData = try binary.readString(quantityOfBytes: remainingBytes, encoding: .utf8)
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return ErrorFrame(
            header: header,
            errorCode: errorCode,
            errorData: errorData
        )
    }
}

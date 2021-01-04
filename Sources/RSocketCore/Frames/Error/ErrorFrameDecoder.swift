import NIO

public struct ErrorFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> ErrorFrame {
        guard let codeValue: UInt32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let errorCode = ErrorCode(rawValue: codeValue)
        let errorData: String
        if buffer.readableBytes > 0 {
            guard let string = buffer.readString(length: buffer.readableBytes) else {
                throw FrameError.stringContainsInvalidCharacters
            }
            errorData = string
        } else {
            errorData = ""
        }
        return ErrorFrame(
            header: header,
            errorCode: errorCode,
            errorData: errorData
        )
    }
}

import Foundation
import NIO

public struct ResumeOkFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> ResumeOkFrame {
        guard let lastReceivedClientPosition: Int64 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        return ResumeOkFrame(
            header: header,
            lastReceivedClientPosition: lastReceivedClientPosition
        )
    }
}

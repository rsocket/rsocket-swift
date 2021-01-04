import Foundation
import NIO

public struct RequestNFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> RequestNFrame {
        guard let requestN: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        return RequestNFrame(header: header, requestN: requestN)
    }
}

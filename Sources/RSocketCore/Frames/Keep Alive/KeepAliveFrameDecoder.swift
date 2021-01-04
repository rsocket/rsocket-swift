import Foundation
import NIO

public struct KeepAliveFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> KeepAliveFrame {
        guard let lastReceivedPosition: Int64 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let data: Data
        if buffer.readableBytes > 0 {
            data = buffer.readData(length: buffer.readableBytes) ?? Data()
        } else {
            data = Data()
        }
        return KeepAliveFrame(
            header: header,
            lastReceivedPosition: lastReceivedPosition,
            data: data
        )
    }
}

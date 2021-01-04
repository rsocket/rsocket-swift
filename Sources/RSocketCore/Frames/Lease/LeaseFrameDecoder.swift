import Foundation
import NIO

public struct LeaseFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> LeaseFrame {
        guard let timeToLive: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let numberOfRequests: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let metadata: Data?
        if header.flags.contains(.metadata) {
            if buffer.readableBytes > 0 {
                metadata = buffer.readData(length: buffer.readableBytes) ?? Data()
            } else {
                metadata = Data()
            }
        } else {
            metadata = nil
        }
        return LeaseFrame(
            header: header,
            timeToLive: timeToLive,
            numberOfRequests: numberOfRequests,
            metadata: metadata
        )
    }
}

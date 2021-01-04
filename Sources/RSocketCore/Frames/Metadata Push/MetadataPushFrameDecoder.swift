import Foundation
import NIO

public struct MetadataPushFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> MetadataPushFrame {
        let metadata: Data
        if buffer.readableBytes > 0 {
            metadata = buffer.readData(length: buffer.readableBytes) ?? Data()
        } else {
            metadata = Data()
        }
        return MetadataPushFrame(header: header, metadata: metadata)
    }
}

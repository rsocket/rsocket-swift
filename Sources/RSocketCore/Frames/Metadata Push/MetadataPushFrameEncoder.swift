import Foundation
import NIO

public struct MetadataPushFrameEncoder: FrameEncoder {
    public func encode(frame: MetadataPushFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeData(frame.metadata)
        return buffer
    }
}

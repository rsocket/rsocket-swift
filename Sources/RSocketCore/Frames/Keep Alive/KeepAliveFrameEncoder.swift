import Foundation
import NIO

public struct KeepAliveFrameEncoder: FrameEncoder {
    public func encode(frame: KeepAliveFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.lastReceivedPosition)
        buffer.writeData(frame.data)
        return buffer
    }
}

import Foundation
import NIO

public struct RequestNFrameEncoder: FrameEncoder {
    public func encode(frame: RequestNFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.requestN)
        return buffer
    }
}

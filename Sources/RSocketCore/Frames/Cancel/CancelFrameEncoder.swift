import NIO

public struct CancelFrameEncoder: FrameEncoder {
    public func encode(frame: CancelFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
    }
}

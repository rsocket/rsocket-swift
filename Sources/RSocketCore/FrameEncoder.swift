import NIO

public protocol FrameEncoder {
    associatedtype Frame
    func encode(frame: Frame, using allocator: ByteBufferAllocator) throws -> ByteBuffer
}

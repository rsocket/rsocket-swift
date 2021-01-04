import NIO

public struct FrameHeaderEncoder {
    public func encode(header: FrameHeader, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = allocator.buffer(capacity: FrameHeader.lengthInBytes)
        buffer.writeInteger(header.streamId)
        // shift type by amount of flag bits
        let typeBits = UInt16(header.type.rawValue << 10)
        // only use trailing 10 bits for flags
        let flagBits = header.flags.rawValue & 0b0000001111111111
        buffer.writeInteger(typeBits | flagBits)
        return buffer
    }
}

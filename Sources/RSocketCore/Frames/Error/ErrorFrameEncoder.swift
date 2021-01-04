import NIO

public struct ErrorFrameEncoder: FrameEncoder {
    public func encode(frame: ErrorFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.errorCode.rawValue)
        if !frame.errorData.isEmpty {
            let bytesWritten = buffer.writeString(frame.errorData)
            guard bytesWritten > 0 else {
                throw FrameError.stringContainsInvalidCharacters
            }
        }
        return buffer
    }
}

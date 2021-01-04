import Foundation
import NIO

public struct ResumeOkFrameEncoder: FrameEncoder {
    public func encode(frame: ResumeOkFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.lastReceivedClientPosition)
        return buffer
    }
}

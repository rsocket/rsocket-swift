import Foundation
import NIO

public struct LeaseFrameEncoder: FrameEncoder {
    public func encode(frame: LeaseFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.timeToLive)
        buffer.writeInteger(frame.numberOfRequests)
        if let metadata = frame.metadata {
            buffer.writeData(metadata)
        }
        return buffer
    }
}

import Foundation
import NIO

public struct ResumeFrameEncoder: FrameEncoder {
    public func encode(frame: ResumeFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        buffer.writeInteger(frame.majorVersion)
        buffer.writeInteger(frame.minorVersion)
        guard frame.resumeIdentificationToken.count <= UInt16.max else {
            throw FrameError.resume(.resumeIdentificationTokenTooBig)
        }
        buffer.writeInteger(UInt16(frame.resumeIdentificationToken.count))
        buffer.writeData(frame.resumeIdentificationToken)
        buffer.writeInteger(frame.lastReceivedServerPosition)
        buffer.writeInteger(frame.firstAvailableClientPosition)
        return buffer
    }
}

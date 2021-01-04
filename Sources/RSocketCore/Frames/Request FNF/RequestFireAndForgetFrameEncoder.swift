import Foundation
import NIO

public struct RequestFireAndForgetFrameEncoder: FrameEncoder {
    public func encode(frame: RequestFireAndForgetFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try FrameHeaderEncoder().encode(header: frame.header, using: allocator)
        if let metadata = frame.metadata {
            guard metadata.count <= FrameConstants.metadataMaximumLength else {
                throw FrameError.metadataTooBig
            }
            let metadataLengthBytes = UInt32(metadata.count).bytes.suffix(FrameConstants.metadataLengthFieldLengthInBytes)
            buffer.writeBytes(metadataLengthBytes)
            buffer.writeData(metadata)
        }
        buffer.writeData(frame.payload)
        return buffer
    }
}

import Foundation
import NIO

public struct RequestStreamFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> RequestStreamFrame {
        guard let initialRequestN: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let metadata: Data?
        if header.flags.contains(.metadata) {
            guard let metadataLengthBytes = buffer.readBytes(length: FrameConstants.metadataLengthFieldLengthInBytes) else {
                throw FrameError.tooSmall
            }
            let metadataLength = Int(bytes: metadataLengthBytes)
            guard let metadataData = buffer.readData(length: metadataLength) else {
                throw FrameError.tooSmall
            }
            metadata = metadataData
        } else {
            metadata = nil
        }
        let payload: Data
        if buffer.readableBytes > 0 {
            payload = buffer.readData(length: buffer.readableBytes) ?? Data()
        } else {
            payload = Data()
        }
        return RequestStreamFrame(
            header: header,
            initialRequestN: initialRequestN,
            metadata: metadata,
            payload: payload
        )
    }
}

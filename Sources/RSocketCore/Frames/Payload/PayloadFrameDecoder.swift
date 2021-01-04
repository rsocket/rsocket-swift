import Foundation
import NIO

public struct PayloadFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> PayloadFrame {
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
        return PayloadFrame(header: header, metadata: metadata, payload: payload)
    }
}

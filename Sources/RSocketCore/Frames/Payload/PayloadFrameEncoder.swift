import BinaryKit
import Foundation

public struct PayloadFrameEncoder: FrameEncoder {
    public func encode(frame: PayloadFrame) throws -> Data {
        var binary = Binary()
        
        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))
        
        if let metadata = frame.metadata {
            guard metadata.count <= FrameConstants.metadataMaximumLength else {
                throw FrameError.metadataTooBig
            }
            let metadataLengthBits = UInt32(metadata.count).bits.suffix(FrameConstants.metadataLengthFieldLengthInBytes)
            for bit in metadataLengthBits {
                binary.writeBit(bit: bit)
            }
            binary.writeBytes(Array(metadata))
        }

        binary.writeBytes(Array(frame.payload))
        
        return Data(binary.bytesStore)
    }
}

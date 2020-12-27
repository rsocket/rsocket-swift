import BinaryKit
import Foundation

public struct MetadataPushFrameEncoder: FrameEncoder {
    public func encode(frame: MetadataPushFrame) throws -> Data {
        var binary = Binary()
        
        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))

        binary.writeBytes(Array(frame.metadata))
        
        return Data(binary.bytesStore)
    }
}

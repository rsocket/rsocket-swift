import BinaryKit
import Foundation

public struct KeepAliveFrameEncoder: FrameEncoder {
    public func encode(frame: KeepAliveFrame) throws -> Data {
        var binary = Binary()
        
        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))
        
        binary.writeInt(frame.lastReceivedPosition)

        binary.writeBytes(Array(frame.data))
        
        return Data(binary.bytesStore)
    }
}

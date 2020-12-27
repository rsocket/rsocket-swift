import BinaryKit
import Foundation

public struct RequestNFrameEncoder: FrameEncoder {
    public func encode(frame: RequestNFrame) throws -> Data {
        var binary = Binary()
        
        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))
        
        binary.writeInt(frame.requestN)
        
        return Data(binary.bytesStore)
    }
}

import BinaryKit
import Foundation

public struct ErrorFrameEncoder: FrameEncoder {
    public func encode(frame: ErrorFrame) throws -> Data {
        var binary = Binary()
        
        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))
        
        binary.writeInt(frame.errorCode.rawValue)

        binary.writeString(frame.errorData)
        
        return Data(binary.bytesStore)
    }
}

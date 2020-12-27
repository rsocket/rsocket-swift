import BinaryKit
import Foundation

public struct LeaseFrameEncoder: FrameEncoder {
    public func encode(frame: LeaseFrame) throws -> Data {
        var binary = Binary()
        
        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))
        
        binary.writeInt(frame.timeToLive)

        binary.writeInt(frame.numberOfRequests)

        if let metadata = frame.metadata {
            binary.writeBytes(Array(metadata))
        }
        
        return Data(binary.bytesStore)
    }
}

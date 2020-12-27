import BinaryKit
import Foundation

public struct ResumeOkFrameEncoder: FrameEncoder {
    public func encode(frame: ResumeOkFrame) throws -> Data {
        var binary = Binary()

        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))

        binary.writeInt(frame.lastReceivedClientPosition)

        return Data(binary.bytesStore)
    }
}

import BinaryKit
import Foundation

public struct ResumeFrameEncoder: FrameEncoder {
    public func encode(frame: ResumeFrame) throws -> Data {
        var binary = Binary()

        let headerData = try FrameHeaderEncoder().encode(header: frame.header)
        binary.writeBytes(Array(headerData))

        binary.writeInt(frame.majorVersion)

        binary.writeInt(frame.minorVersion)

        if let token = frame.resumeIdentificationToken {
            guard token.count <= UInt16.max else {
                throw FrameError.setup(.resumeIdentificationTokenTooBig)
            }
            binary.writeInt(UInt16(token.count))
            binary.writeBytes(Array(token))
        }

        binary.writeInt(frame.lastReceivedServerPosition)

        binary.writeInt(frame.firstAvailableClientPosition)

        return Data(binary.bytesStore)
    }
}

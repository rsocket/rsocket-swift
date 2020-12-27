import BinaryKit
import Foundation

public struct FrameHeaderEncoder {
    private enum Constants {
        static let typeFieldLength = 6
        static let flagsFieldLength = 10
    }

    public func encode(header: FrameHeader) throws -> Data {
        var binary = Binary()

        binary.writeInt(header.streamId)

        let typeBits = header.type.rawValue.bits.suffix(Constants.typeFieldLength)
        for bit in typeBits {
            binary.writeBit(bit: bit)
        }

        let flagsBits = header.flags.rawValue.bits.suffix(Constants.flagsFieldLength)
        for bit in flagsBits {
            binary.writeBit(bit: bit)
        }

        return Data(binary.bytesStore)
    }
}

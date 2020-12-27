import BinaryKit
import Foundation

public struct FrameHeaderDecoder {
    private enum Constants {
        static let typeFieldLength = 6
        static let flagsFieldLength = 10
    }

    public func decode(data: Data) throws -> FrameHeader {
        let streamId: Int32
        let type: FrameType
        let flags: FrameFlags
        var binary = Binary(bytes: Array(data))
        do {
            streamId = try binary.readInt32()

            let typeBits = UInt8(try binary.readBits(Constants.typeFieldLength))
            guard let frameType = FrameType(rawValue: typeBits) else {
                throw FrameError.header(.unknownType(typeBits))
            }
            type = frameType

            let flagBits = UInt16(try binary.readBits(Constants.flagsFieldLength))
            flags = FrameFlags(rawValue: flagBits)
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return FrameHeader(streamId: streamId, type: type, flags: flags)
    }
}

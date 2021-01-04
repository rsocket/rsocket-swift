import NIO

public struct FrameHeaderDecoder {
    public func decode(buffer: inout ByteBuffer) throws -> FrameHeader {
        guard let streamId: Int32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let typeAndFlagBytes: UInt16 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        // leading 6 bits are the type
        let typeValue = UInt8(truncatingIfNeeded: typeAndFlagBytes >> 10)
        guard let type = FrameType(rawValue: typeValue) else {
            throw FrameError.header(.unknownType(typeValue))
        }
        // trailing 10 bits are the flags
        let flagValue = typeAndFlagBytes & 0b0000001111111111
        let flags = FrameFlags(rawValue: flagValue)
        return FrameHeader(streamId: streamId, type: type, flags: flags)
    }
}

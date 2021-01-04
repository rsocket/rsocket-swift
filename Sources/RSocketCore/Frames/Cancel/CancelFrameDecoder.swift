import NIO

public struct CancelFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> CancelFrame {
        CancelFrame(header: header)
    }
}

import NIO

public protocol FrameDecoder {
    associatedtype Frame
    func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> Frame
}

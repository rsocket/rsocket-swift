import BinaryKit
import Foundation

public struct CancelFrameEncoder: FrameEncoder {
    public func encode(frame: CancelFrame) throws -> Data {
        try FrameHeaderEncoder().encode(header: frame.header)
    }
}

import BinaryKit
import Foundation

public struct CancelFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> CancelFrame {
        CancelFrame(header: header)
    }
}

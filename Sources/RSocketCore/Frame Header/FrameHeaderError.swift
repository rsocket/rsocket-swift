import Foundation

public enum FrameHeaderError: Error {
    case invalidStreamId(Int32)
    case unknownType(UInt8)
}

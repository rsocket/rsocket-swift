import Foundation

public protocol FrameDecoder {
    associatedtype Frame
    func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> Frame
}

import Foundation

public protocol FrameEncoder {
    associatedtype Frame
    func encode(frame: Frame) throws -> Data
}

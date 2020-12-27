import Foundation

extension RequestStreamFrame {
    public func validate() throws {
        if initialRequestN <= 0 {
            throw FrameError.requestStream(.initialRequestNIsNotPositive)
        }
    }
}

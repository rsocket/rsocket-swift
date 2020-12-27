import Foundation

extension RequestChannelFrame {
    public func validate() throws {
        if initialRequestN <= 0 {
            throw FrameError.requestChannel(.initialRequestNIsNotPositive)
        }
    }
}

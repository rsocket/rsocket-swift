import Foundation

extension KeepAliveFrame {
    public func validate() throws {
        if header.streamId != 0 {
            throw FrameError.keepAlive(.streamIdIsNotZero)
        }
        if lastReceivedPosition < 0 {
            throw FrameError.keepAlive(.lastReceivedPositionIsNotPositiveOrZero)
        }
    }
}

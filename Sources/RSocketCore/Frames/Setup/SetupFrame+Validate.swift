import Foundation

extension SetupFrame {
    public func validate() throws {
        if header.streamId != 0 {
            throw FrameError.setup(.streamIdIsNotZero)
        }
        if timeBetweenKeepaliveFrames <= 0 {
            throw FrameError.setup(.timeBetweenKeepaliveFramesIsNotPositive)
        }
        if maxLifetime <= 0 {
            throw FrameError.setup(.maxLifetimeIsNotPositive)
        }
    }
}

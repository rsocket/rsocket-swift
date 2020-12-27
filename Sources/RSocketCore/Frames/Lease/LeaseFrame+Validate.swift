import Foundation

extension LeaseFrame {
    public func validate() throws {
        if header.streamId != 0 {
            throw FrameError.lease(.streamIdIsNotZero)
        }
        if timeToLive < 0 {
            throw FrameError.lease(.timeToLiveIsNotPositiveOrZero)
        }
        if numberOfRequests < 0 {
            throw FrameError.lease(.numberOfRequestsIsNotPositiveOrZero)
        }
    }
}

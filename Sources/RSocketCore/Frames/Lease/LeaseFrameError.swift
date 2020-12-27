import Foundation

public enum LeaseFrameError: Error {
    case streamIdIsNotZero
    case timeToLiveIsNotPositiveOrZero
    case numberOfRequestsIsNotPositiveOrZero
}

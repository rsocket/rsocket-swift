import Foundation

public enum KeepAliveFrameError: Error {
    case streamIdIsNotZero
    case lastReceivedPositionIsNotPositiveOrZero
}

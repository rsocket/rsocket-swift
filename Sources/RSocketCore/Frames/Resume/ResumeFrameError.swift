import Foundation

public enum ResumeFrameError: Error {
    case lastReceivedServerPositionIsNotZeroOrPositive
    case firstAvailableClientPositionIsNotZeroOrPositive
}

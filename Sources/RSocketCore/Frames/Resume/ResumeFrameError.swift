import Foundation

public enum ResumeFrameError: Error {
    case resumeIdentificationTokenTooBig
    case lastReceivedServerPositionIsNotZeroOrPositive
    case firstAvailableClientPositionIsNotZeroOrPositive
}

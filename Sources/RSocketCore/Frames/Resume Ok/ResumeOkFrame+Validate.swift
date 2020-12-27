import Foundation

extension ResumeOkFrame {
    public func validate() throws {
        if lastReceivedClientPosition < 0 {
            throw FrameError.resumeOk(.lastReceivedClientPositionIsNotZeroOrPositive)
        }
    }
}

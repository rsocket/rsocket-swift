import Foundation

extension ResumeFrame {
    public func validate() throws {
        if lastReceivedServerPosition < 0 {
            throw FrameError.resume(.lastReceivedServerPositionIsNotZeroOrPositive)
        }
        if firstAvailableClientPosition < 0 {
            throw FrameError.resume(.firstAvailableClientPositionIsNotZeroOrPositive)
        }
    }
}

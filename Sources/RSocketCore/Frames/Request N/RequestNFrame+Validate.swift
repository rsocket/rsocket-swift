import Foundation

extension RequestNFrame {
    public func validate() throws {
        if requestN <= 0 {
            throw FrameError.requestN(.requestNIsNotPositive)
        }
    }
}

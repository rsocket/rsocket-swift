import Foundation

extension ExtensionFrame {
    public func validate() throws {
        if extendedType < 0 {
            throw FrameError.extension(.extendedTypeIsNotPositiveOrZero)
        }
    }
}

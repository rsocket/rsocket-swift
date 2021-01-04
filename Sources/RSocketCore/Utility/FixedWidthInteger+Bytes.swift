import Foundation

extension FixedWidthInteger {
    internal var bytes: [UInt8] {
        (0..<bitWidth)
            .map { UInt8(truncatingIfNeeded: self >> $0) }
            .reversed()
    }
}

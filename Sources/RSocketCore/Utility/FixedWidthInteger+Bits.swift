import Foundation

extension FixedWidthInteger {
    internal var bits: [UInt8] {
        (0..<bitWidth)
            .map { UInt8(truncatingIfNeeded: (self >> $0) & 0x01) }
            .reversed()
    }
}

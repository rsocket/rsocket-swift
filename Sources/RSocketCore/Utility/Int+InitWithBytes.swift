import Foundation

extension Int {
    internal init(bytes: [UInt8]) {
        self = bytes.reduce(.zero) {
            $0 << UInt8.bitWidth | Int($1)
        }
    }
}

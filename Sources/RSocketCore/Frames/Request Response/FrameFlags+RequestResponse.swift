import Foundation

extension FrameFlags {
    /// (F)ollows: More fragments follow this fragment
    public static let requestResponseFollows = FrameFlags(rawValue: 1 << 7)
}

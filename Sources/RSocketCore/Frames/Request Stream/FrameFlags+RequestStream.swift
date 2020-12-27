import Foundation

extension FrameFlags {
    /// (F)ollows: More fragments follow this fragment
    public static let requestStreamFollows = FrameFlags(rawValue: 1 << 7)
}

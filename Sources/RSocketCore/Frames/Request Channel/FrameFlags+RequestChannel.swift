import Foundation

extension FrameFlags {
    /// (F)ollows: More fragments follow this fragment
    public static let requestChannelFollows = FrameFlags(rawValue: 1 << 7)

    /**
     (C)omplete: bit to indicate stream completion

     If set, `onComplete()` or equivalent will be invoked on Subscriber/Observer.
     */
    public static let requestChannelComplete = FrameFlags(rawValue: 1 << 6)
}

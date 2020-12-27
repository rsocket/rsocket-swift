import Foundation

extension FrameFlags {
    /// (F)ollows: More fragments follow this fragment
    public static let payloadFollows = FrameFlags(rawValue: 1 << 7)

    /**
     (C)omplete: bit to indicate stream completion

     If set, `onComplete()` or equivalent will be invoked on Subscriber/Observer.
     */
    public static let payloadComplete = FrameFlags(rawValue: 1 << 6)

    /**
     (N)ext: bit to indicate Next (Payload Data and/or Metadata present)

     If set, `onNext(Payload)` or equivalent will be invoked on Subscriber/Observer.
     */
    public static let payloadNext = FrameFlags(rawValue: 1 << 5)
}

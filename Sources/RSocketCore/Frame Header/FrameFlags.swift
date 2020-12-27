import Foundation

public struct FrameFlags: OptionSet {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    /**
     (I)gnore: Ignore frame if not understood

     The (I)gnore flag is used for extension of the protocol.
     A value of 0 in a frame for this flag indicates the protocol can't ignore this frame.
     An implementation MAY send an ERROR[CONNECTION_ERROR] frame and close the underlying transport
     connection on reception of a frame that it does not understand with this bit not set.
     */
    public static let ignore = FrameFlags(rawValue: 1 << 9)

    /// (M)etadata: Indicates that the frame contains metadata
    public static let metadata = FrameFlags(rawValue: 1 << 8)
}

import Foundation

extension FrameFlags {
    /**
     (R)esume Enable: Client requests resume capability if possible
     
     Resume Identification Token present.
     */
    public static let setupResume = FrameFlags(rawValue: 1 << 7)

    /// (L)ease: Will honor `LEASE` (or not)
    public static let setupLease = FrameFlags(rawValue: 1 << 6)
}

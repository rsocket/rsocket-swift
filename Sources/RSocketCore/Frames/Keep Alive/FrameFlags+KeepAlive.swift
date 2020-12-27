import Foundation

extension FrameFlags {
    /// (R)espond with `KEEPALIVE` or not
    public static let keepAliveResume = FrameFlags(rawValue: 1 << 7)
}

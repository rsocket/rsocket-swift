import Foundation

extension FrameHeader {
    public func validate() throws {
        if streamId < 0 {
            throw FrameError.header(.invalidStreamId(streamId))
        }
    }
}

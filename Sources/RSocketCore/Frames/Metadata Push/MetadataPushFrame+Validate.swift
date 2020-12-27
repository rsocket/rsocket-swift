import Foundation

extension MetadataPushFrame {
    public func validate() throws {
        if header.streamId != 0 {
            throw FrameError.metadataPush(.streamIdIsNotZero)
        }
    }
}

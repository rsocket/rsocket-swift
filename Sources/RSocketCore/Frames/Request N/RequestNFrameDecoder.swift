import BinaryKit
import Foundation

public struct RequestNFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> RequestNFrame {
        let requestN: Int32
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            requestN = try binary.readInt32()
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return RequestNFrame(header: header, requestN: requestN)
    }
}

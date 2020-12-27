import BinaryKit
import Foundation

public struct ResumeFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, dataExcludingHeader: Data) throws -> ResumeFrame {
        let majorVersion: UInt16
        let minorVersion: UInt16
        let resumeIdentificationToken: Data?
        let lastReceivedServerPosition: Int64
        let firstAvailableClientPosition: Int64
        var binary = Binary(bytes: Array(dataExcludingHeader))
        do {
            majorVersion = try binary.readUInt16()

            minorVersion = try binary.readUInt16()

            if header.flags.contains(.setupResume) {
                let resumeTokenLength = try binary.readUInt16()
                resumeIdentificationToken = Data(try binary.readBytes(Int(resumeTokenLength)))
            } else {
                resumeIdentificationToken = nil
            }

            lastReceivedServerPosition = try binary.readInt64()

            firstAvailableClientPosition = try binary.readInt64()
        } catch let error as BinaryError {
            throw FrameError.binary(error)
        }
        return ResumeFrame(
            header: header,
            majorVersion: majorVersion,
            minorVersion: minorVersion,
            resumeIdentificationToken: resumeIdentificationToken,
            lastReceivedServerPosition: lastReceivedServerPosition,
            firstAvailableClientPosition: firstAvailableClientPosition
        )
    }
}

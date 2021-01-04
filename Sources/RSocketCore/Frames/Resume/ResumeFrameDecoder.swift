import Foundation
import NIO

public struct ResumeFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> ResumeFrame {
        guard let majorVersion: UInt16 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let minorVersion: UInt16 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let resumeTokenLength: UInt16 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let resumeIdentificationToken = buffer.readData(length: Int(resumeTokenLength)) else {
            throw FrameError.tooSmall
        }
        guard let lastReceivedServerPosition: Int64 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        guard let firstAvailableClientPosition: Int64 = buffer.readInteger() else {
            throw FrameError.tooSmall
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

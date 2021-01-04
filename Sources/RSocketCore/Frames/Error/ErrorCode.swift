import Foundation

public enum ErrorCode {
    /// Reserved
    case reservedLower

    /**
     The Setup frame is invalid for the server (it could be that the client is too recent for the old server)

     Stream ID MUST be `0`.
     */
    case invalidSetup

    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    case unsupportedSetup

    /**
     The server rejected the setup, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    case rejectedSetup

    /**
     The server rejected the resume, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    case rejectedResume

    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MAY close the connection immediately without waiting for outstanding streams to terminate.
     */
    case connectionError

    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MUST wait for outstanding streams to terminate before closing the connection. New requests MAY not be accepted.
     */
    case connectionClose

    /**
     Application layer logic generating a Reactive Streams `onError` event

     Stream ID MUST be > `0`.
     */
    case applicationError

    /**
     Despite being a valid request, the Responder decided to reject it

     Stream ID MUST be > `0`. The Responder guarantees that it didn't process the request. The reason for the rejection is explained in the Error Data section.
     */
    case rejected

    /**
     The Responder canceled the request but may have started processing it (similar to `REJECTED` but doesn't guarantee lack of side-effects)

     Stream ID MUST be > `0`.
     */
    case canceled

    /**
     The request is invalid

     Stream ID MUST be > `0`.
     */
    case invalid

    /// Reserved for Extension Use
    case reservedUpper

    /// Error code not listed in this enumeration.
    case other(UInt32)
}

extension ErrorCode: RawRepresentable {
    public var rawValue: UInt32 {
        switch self {
        case .reservedLower:
            return 0x00000000

        case .invalidSetup:
            return 0x00000001

        case .unsupportedSetup:
            return 0x00000002

        case .rejectedSetup:
            return 0x00000003

        case .rejectedResume:
            return 0x00000004

        case .connectionError:
            return 0x00000101

        case .connectionClose:
            return 0x00000102

        case .applicationError:
            return 0x00000201

        case .rejected:
            return 0x00000202

        case .canceled:
            return 0x00000203

        case .invalid:
            return 0x00000204

        case .reservedUpper:
            return 0xFFFFFFFF

        case let .other(code):
            return code
        }
    }

    public init(rawValue: UInt32) {
        switch rawValue {
        case ErrorCode.reservedLower.rawValue:
            self = .reservedLower

        case ErrorCode.invalidSetup.rawValue:
            self = .invalidSetup

        case ErrorCode.unsupportedSetup.rawValue:
            self = .unsupportedSetup

        case ErrorCode.rejectedSetup.rawValue:
            self = .rejectedSetup

        case ErrorCode.rejectedResume.rawValue:
            self = .rejectedResume

        case ErrorCode.connectionError.rawValue:
            self = .connectionError

        case ErrorCode.connectionClose.rawValue:
            self = .connectionClose

        case ErrorCode.applicationError.rawValue:
            self = .applicationError

        case ErrorCode.rejected.rawValue:
            self = .rejected

        case ErrorCode.canceled.rawValue:
            self = .canceled

        case ErrorCode.invalid.rawValue:
            self = .invalid

        case ErrorCode.reservedUpper.rawValue:
            self = .reservedUpper

        default:
            self = .other(rawValue)
        }
    }
}

extension ErrorCode {
    public var isProtocolCode: Bool {
        0x0001 <= self.rawValue && self.rawValue <= 0x00300
    }

    public var isApplicationLayerError: Bool {
        0x00301 <= self.rawValue && self.rawValue <= 0xFFFFFFFE
    }
}

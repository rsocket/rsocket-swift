import Foundation

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

    public var isProtocolCode: Bool {
        0x0001 <= self.rawValue && self.rawValue <= 0x00300
    }

    public var isApplicationLayerError: Bool {
        0x00301 <= self.rawValue && self.rawValue <= 0xFFFFFFFE
    }
}

import Foundation

extension ErrorFrame {
    public func validate() throws {
        if header.streamId == 0 {
            switch errorCode {
            case .invalidSetup, .unsupportedSetup, .rejectedSetup, .connectionError, .connectionClose:
                break

            default:
                throw FrameError.error(.invalidErrorCode(errorCode))
            }
        } else {
            switch errorCode {
            case .applicationError, .rejected, .canceled, .invalid:
                break

            case .other where errorCode.isApplicationLayerError:
                break

            default:
                throw FrameError.error(.invalidErrorCode(errorCode))
            }
        }
    }
}

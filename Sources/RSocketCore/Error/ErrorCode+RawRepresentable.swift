/*
 * Copyright 2015-present the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
}

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

public struct AuthenticationType: RawRepresentable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension AuthenticationType {
    static let simple = Self(rawValue: "simple")
    static let bearer = Self(rawValue: "bearer")
}


public enum WellKnownAuthenticationType : Equatable {
    case UNPARSEABLE_AUTH_TYPE
    case UNKNOWN_RESERVED_AUTH_TYPE
    case SIMPLE
    case BEARER

    private static var typesByAuthId = [WellKnownAuthenticationType](repeating: .UNKNOWN_RESERVED_AUTH_TYPE, count: 128)

    public static func fromIdentifier(id: Int8) -> WellKnownAuthenticationType {
        if id < 0x00 || id > 0x7F {
            return .UNPARSEABLE_AUTH_TYPE
        }
        return typesByAuthId[Int(id)]
    }
    
    public var identifier: UInt8 {
        switch self {
        case .UNPARSEABLE_AUTH_TYPE :
            return UInt8(0xFE)
        case .UNKNOWN_RESERVED_AUTH_TYPE:
            return UInt8(0xFF)
        case .SIMPLE:
            return 0x00
        case .BEARER:
            return 0x01
        }
    }
}

//public enum WellKnownAuthenticationType {
//    case BEARER
//    case SIMPLE
//    case UNPARSEABLE_AUTH_TYPE
//    case UNKNOWN_RESERVED_AUTH_TYPE
//
//    public var identifier: UInt8 {
//        switch self {
//        case .SIMPLE:
//            return UInt8(0x00)
//        case .BEARER:
//            return UInt8(0x01)
//        case .UNKNOWN_RESERVED_AUTH_TYPE:
//            return UInt8(0xFF)
//        case .UNPARSEABLE_AUTH_TYPE:
//            return UInt8(0xFE)
//        }
//    }
//}

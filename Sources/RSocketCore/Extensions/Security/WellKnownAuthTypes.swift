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

import NIOCore

public struct WellKnownAuthenticationTypeCode: RawRepresentable, Hashable {
    /// rawValue is guaranteed to be in the range `0...127`.
    public let rawValue: UInt8
    public init?(rawValue: UInt8) {
        guard rawValue & 0b1000_0000 == 0 else { return nil }
        self.rawValue = rawValue
    }
}
extension WellKnownAuthenticationTypeCode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt8) {
        guard let value = Self(rawValue: value) else {
            fatalError("Well Know Authentication Type Codes are only allowed to be between 0 and 127.")
        }
        self = value
    }
}

public extension WellKnownAuthenticationTypeCode {
    static let simple: Self = 0x00
    static let bearer: Self = 0x01
}

public extension AuthenticationType {
    static let wellKnownAuthenticationTypes: [(WellKnownAuthenticationTypeCode, AuthenticationType)] = [
        (.simple, .simple),
        (.bearer, .bearer),
    ]
}

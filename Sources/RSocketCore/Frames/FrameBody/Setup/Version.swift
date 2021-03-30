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

/// A version of the RSocket protocol
public struct Version: Hashable {
    /// Major version number of the protocol
    public let major: UInt16

    /// Minor version number of the protocol
    public let minor: UInt16
}

public extension Version {
    static let v1_0 = Version(major: 1, minor: 0)
    static let current = Version.v1_0
}

extension Version: Comparable {
    public static func < (lhs: Version, rhs: Version) -> Bool {
        guard lhs.major == rhs.major else {
            return lhs.major < rhs.major
        }
        return lhs.minor < rhs.minor
    }
}

extension Version: CustomStringConvertible {
    public var description: String { "\(major).\(minor)" }
}

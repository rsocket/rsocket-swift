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

/// A identifier of a stream.
internal struct StreamID: RawRepresentable {
    internal var rawValue: Int32
}

extension StreamID: Hashable {}

extension StreamID {
    /// Stream ID for any operation involving the connection
    internal static let connection = StreamID(rawValue: 0)
}

extension StreamID: CustomDebugStringConvertible {
    var debugDescription: String {
        if self == .connection {
            return ".connection"
        } else {
            return rawValue.description
        }
    }
}

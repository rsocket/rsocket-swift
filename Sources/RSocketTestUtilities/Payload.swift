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

import RSocketCore

extension Payload: ExpressibleByStringLiteral {
    /// used to create payload with the given string as a UTF-8 encoded data and no metadata
    /// - Parameter value: string that is encoded as UTF-8 and put into the data segment of the payload
    public init(stringLiteral value: String) {
        self.init(data: value.data(using: .utf8)!)
    }
}

extension Payload: CustomDebugStringConvertible {
    public var debugDescription: String {
        let dataDescription = String(data: data, encoding: .utf8)?.debugDescription ?? data.debugDescription
        let metadataDescription = metadata.map { String(data: $0, encoding: .utf8)?.debugDescription ?? $0.debugDescription }
        if let metadata = metadataDescription {
            return "Payload(metadata: \(metadata), data: \(dataDescription))"
        } else {
            return "Payload(data: \(dataDescription))"
        }
    }
}

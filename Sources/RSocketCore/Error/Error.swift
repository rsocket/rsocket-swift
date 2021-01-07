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

/**
 Errors are used on individual requests/streams as well
 as connection errors and in response to `SETUP` frames.
 */
public struct Error: Swift.Error {
    /// The type of the error
    public let code: ErrorCode

    /// Error information
    public let message: String

    public init(
        code: ErrorCode,
        message: String
    ) {
        self.code = code
        self.message = message
    }
}

extension Error {
    public var isProtocolError: Bool {
        0x0001 <= code.rawValue && code.rawValue <= 0x00300
    }

    public var isApplicationLayerError: Bool {
        0x00301 <= code.rawValue && code.rawValue <= 0xFFFFFFFE
    }
}

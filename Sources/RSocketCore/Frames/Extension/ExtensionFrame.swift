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

/// Used To extend more frame types as well as extensions
public struct ExtensionFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     Extended type information

     Value MUST be > `0`.
     */
    public let extendedType: Int32

    /// Optional metadata of this frame
    public let metadata: Data?

    /// The payload for the extended type
    public let payload: Data

    public init(
        header: FrameHeader,
        extendedType: Int32,
        metadata: Data?,
        payload: Data
    ) {
        self.header = header
        self.extendedType = extendedType
        self.metadata = metadata
        self.payload = payload
    }
}

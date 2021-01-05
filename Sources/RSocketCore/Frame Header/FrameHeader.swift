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

public struct FrameHeader {
    public static let lengthInBytes = 6

    /// The id of the corresponding stream
    public let streamId: Int32

    /// The type of the frame
    public let type: FrameType

    /// The flags that are set on the frame
    public let flags: FrameFlags

    public init(
        streamId: Int32,
        type: FrameType,
        flags: FrameFlags
    ) {
        self.streamId = streamId
        self.type = type
        self.flags = flags
    }
}

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

/// The `RESUME_OK` frame is sent in response to a `RESUME` if resuming operation possible
public struct ResumeOkFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// The last implied position the server received from the client
    public let lastReceivedClientPosition: Int64

    public init(
        header: FrameHeader,
        lastReceivedClientPosition: Int64
    ) {
        self.header = header
        self.lastReceivedClientPosition = lastReceivedClientPosition
    }

    public init(lastReceivedClientPosition: Int64) {
        self.header = FrameHeader(streamId: 0, type: .resumeOk, flags: [])
        self.lastReceivedClientPosition = lastReceivedClientPosition
    }
}

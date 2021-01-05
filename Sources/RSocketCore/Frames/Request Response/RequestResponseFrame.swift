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

/// Request single response
public struct RequestResponseFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// Optional metadata of this frame
    public let metadata: Data?

    /// Identification of the service being requested along with parameters for the request
    public let payload: Data

    public init(
        header: FrameHeader,
        metadata: Data?,
        payload: Data
    ) {
        self.header = header
        self.metadata = metadata
        self.payload = payload
    }

    public init(
        streamId: Int32,
        fragmentsFollow: Bool,
        metadata: Data?,
        payload: Data
    ) {
        var flags = FrameFlags()
        if metadata != nil {
            flags.insert(.metadata)
        }
        if fragmentsFollow {
            flags.insert(.requestResponseFollows)
        }
        self.header = FrameHeader(streamId: streamId, type: .requestResponse, flags: flags)
        self.metadata = metadata
        self.payload = payload
    }
}

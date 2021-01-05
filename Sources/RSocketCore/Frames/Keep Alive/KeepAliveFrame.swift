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

/// Indicates to the receiver that the sender is alive
public struct KeepAliveFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     Resume Last Received Position

     Value MUST be > `0`. (optional. Set to all `0`s when not supported.)
     */
    public let lastReceivedPosition: Int64

    /// Data attached to a `KEEPALIVE`
    public let data: Data

    public init(
        header: FrameHeader,
        lastReceivedPosition: Int64,
        data: Data
    ) {
        self.header = header
        self.lastReceivedPosition = lastReceivedPosition
        self.data = data
    }

    public init(
        streamId: Int32,
        respondWithKeepalive: Bool,
        lastReceivedPosition: Int64,
        data: Data
    ) {
        var flags = FrameFlags()
        if respondWithKeepalive {
            flags.insert(.keepAliveRespond)
        }
        self.header = FrameHeader(streamId: streamId, type: .keepalive, flags: flags)
        self.lastReceivedPosition = lastReceivedPosition
        self.data = data
    }
}

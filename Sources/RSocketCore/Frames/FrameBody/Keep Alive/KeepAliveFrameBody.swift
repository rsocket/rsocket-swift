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

/// Indicates to the receiver that the sender is alive
internal struct KeepAliveFrameBody: Hashable {
    /// If the receiver should respond with a `KEEPALIVE`
    internal var respondWithKeepalive: Bool

    /**
     Resume Last Received Position

     Value MUST be > `0`. (optional. Set to all `0`s when not supported.)
     */
    internal var lastReceivedPosition: Int64

    /// Data attached to a `KEEPALIVE`
    internal var data: ByteBuffer
}

extension KeepAliveFrameBody: FrameBodyBoundToConnection {
    func body() -> FrameBody { .keepalive(self) }
    func header() -> FrameHeader {
        var flags = FrameFlags()
        if respondWithKeepalive {
            flags.insert(.keepAliveRespond)
        }
        return FrameHeader(streamId: .connection, type: .keepalive, flags: flags)
    }
}

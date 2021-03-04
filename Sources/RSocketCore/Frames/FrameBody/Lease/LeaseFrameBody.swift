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
 Lease frames MAY be sent by the client-side or server-side Responders and inform the Requester that it may
 send Requests for a period of time and how many it may send during that duration.
 See Lease Semantics for more information.

 The last received `LEASE` frame overrides all previous `LEASE` frame values.
 */
internal struct LeaseFrameBody: Hashable {
    /**
     Time (in milliseconds) for validity of `LEASE` from time of reception

     Value MUST be > `0`.
     */
    internal let timeToLive: Int32

    /**
     Number of Requests that may be sent until next `LEASE`

     Value MUST be > `0`.
     */
    internal let numberOfRequests: Int32

    /// Optional metadata of this frame
    internal let metadata: Data?
}

extension LeaseFrameBody: FrameBodyBoundToConnection {
    func body() -> FrameBody { .lease(self) }
    func header(additionalFlags: FrameFlags) -> FrameHeader {
        var flags = additionalFlags
        if metadata != nil {
            flags.insert(.metadata)
        }
        return FrameHeader(streamId: .connection, type: .lease, flags: flags)
    }
}

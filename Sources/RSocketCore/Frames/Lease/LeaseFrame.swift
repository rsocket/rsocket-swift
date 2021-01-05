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
public struct LeaseFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     Time (in milliseconds) for validity of `LEASE` from time of reception

     Value MUST be > `0`.
     */
    public let timeToLive: Int32

    /**
     Number of Requests that may be sent until next `LEASE`

     Value MUST be > `0`.
     */
    public let numberOfRequests: Int32

    /// Optional metadata of this frame
    public let metadata: Data?

    public init(
        header: FrameHeader,
        timeToLive: Int32,
        numberOfRequests: Int32,
        metadata: Data?
    ) {
        self.header = header
        self.timeToLive = timeToLive
        self.numberOfRequests = numberOfRequests
        self.metadata = metadata
    }
}

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

/// Request a completable stream
internal struct RequestStreamFrame {
    /// The header of this frame
    internal let header: FrameHeader

    /**
     The initial number of items to request

     Value MUST be > `0`.
     */
    internal let initialRequestN: Int32

    /// Identification of the service being requested along with parameters for the request
    internal let payload: Payload

    internal init(
        header: FrameHeader,
        initialRequestN: Int32,
        payload: Payload
    ) {
        self.header = header
        self.initialRequestN = initialRequestN
        self.payload = payload
    }

    internal init(
        streamId: Int32,
        fragmentsFollow: Bool,
        initialRequestN: Int32,
        payload: Payload
    ) {
        var flags = FrameFlags()
        if payload.metadata != nil {
            flags.insert(.metadata)
        }
        if fragmentsFollow {
            flags.insert(.requestStreamFollows)
        }
        self.header = FrameHeader(streamId: streamId, type: .requestStream, flags: flags)
        self.initialRequestN = initialRequestN
        self.payload = payload
    }
}

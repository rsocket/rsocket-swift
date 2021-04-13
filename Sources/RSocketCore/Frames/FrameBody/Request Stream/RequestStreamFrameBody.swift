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

/// Request a completable stream
internal struct RequestStreamFrameBody: Hashable, FragmentableFrameBody {
    /// If true, this is a fragment and at least another payload frame will follow
    internal var fragmentFollows: Bool = false
    
    /**
     The initial number of items to request

     Value MUST be > `0`.
     */
    internal var initialRequestN: Int32

    /// Identification of the service being requested along with parameters for the request
    internal var payload: Payload
}

extension RequestStreamFrameBody: FrameBodyBoundToStream {
    func body() -> FrameBody { .requestStream(self) }
    func header(withStreamId streamId: StreamID) -> FrameHeader {
        var flags = FrameFlags()
        if payload.metadata != nil {
            flags.insert(.metadata)
        }
        if fragmentFollows {
            flags.insert(.fragmentFollows)
        }
        return FrameHeader(streamId: streamId, type: .requestStream, flags: flags)
    }
}

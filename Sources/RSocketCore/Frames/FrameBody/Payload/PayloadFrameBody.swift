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

/**
 Payload on a stream

 For example, response to a request, or message on a channel.
 */
internal struct PayloadFrameBody: Hashable, FragmentableFrameBody {
    /// If true, this is a fragment and at least another payload frame will follow
    internal var fragmentFollows: Bool = false
    
    /// If this frame marks the completion of the stream
    internal let isCompletion: Bool

    /// If this is a new payload
    internal let isNext: Bool

    /// Payload for Reactive Streams `onNext`
    internal let payload: Payload
}

extension PayloadFrameBody: FrameBodyBoundToStream {
    func body() -> FrameBody { .payload(self) }
    func header(withStreamId streamId: StreamID) -> FrameHeader {
        var flags = FrameFlags()
        if payload.metadata != nil {
            flags.insert(.metadata)
        }
        if isCompletion {
            flags.insert(.payloadComplete)
        }
        if isNext {
            flags.insert(.payloadNext)
        }
        if fragmentFollows {
            flags.insert(.fragmentFollows)
        }
        return FrameHeader(streamId: streamId, type: .payload, flags: flags)
    }
}

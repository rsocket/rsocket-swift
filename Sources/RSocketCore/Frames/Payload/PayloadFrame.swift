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
 Payload on a stream

 For example, response to a request, or message on a channel.
 */
public struct PayloadFrame {
    /// The header of this frame
    public let header: FrameHeader

    /// Payload for Reactive Streams `onNext`
    public let payload: Payload

    public init(
        header: FrameHeader,
        payload: Payload
    ) {
        self.header = header
        self.payload = payload
    }

    public init(
        streamId: Int32,
        fragmentsFollow: Bool,
        isCompletion: Bool,
        isNext: Bool,
        payload: Payload
    ) {
        var flags = FrameFlags()
        if payload.metadata != nil {
            flags.insert(.metadata)
        }
        if fragmentsFollow {
            flags.insert(.payloadFollows)
        }
        if isCompletion {
            flags.insert(.payloadComplete)
        }
        if isNext {
            flags.insert(.payloadNext)
        }
        self.header = FrameHeader(streamId: streamId, type: .payload, flags: flags)
        self.payload = payload
    }
}

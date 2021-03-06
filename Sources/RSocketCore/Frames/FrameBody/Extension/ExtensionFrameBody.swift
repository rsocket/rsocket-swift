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

/// Used To extend more frame types as well as extensions
internal struct ExtensionFrameBody: Hashable {
    /// If the frame can be ignored
    internal var canBeIgnored: Bool

    /**
     Extended type information

     Value MUST be > `0`.
     */
    internal var extendedType: Int32

    /// The payload for the extended type
    internal var payload: Payload
}

extension ExtensionFrameBody: FrameBodyBoundToStream {
    func body() -> FrameBody { .ext(self) }
    func header(withStreamId streamId: StreamID) -> FrameHeader {
        var flags = FrameFlags()
        if canBeIgnored {
            flags.insert(.ignore)
        }
        if payload.metadata != nil {
            flags.insert(.metadata)
        }
        return FrameHeader(streamId: streamId, type: .ext, flags: flags)
    }
}

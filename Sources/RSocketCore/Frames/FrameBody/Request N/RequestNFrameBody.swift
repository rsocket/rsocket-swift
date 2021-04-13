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

/// Request `N` more items with Reactive Streams semantics
internal struct RequestNFrameBody: Hashable {
    /**
     The number of items to request

     Value MUST be > `0`.
     */
    internal var requestN: Int32
}

extension RequestNFrameBody: FrameBodyBoundToStream {
    func body() -> FrameBody { .requestN(self) }
    func header(withStreamId streamId: StreamID) -> FrameHeader {
        FrameHeader(streamId: streamId, type: .requestN, flags: [])
    }
}

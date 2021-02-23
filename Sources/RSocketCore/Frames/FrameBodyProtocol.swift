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


/// a frame body which can be send or received
internal protocol FrameBodyProtocol {
    /// puts `self` into a `FrameBody`
    func body() -> FrameBody
}


/// a frame body that can only be send or received on stream `.connection` (stream 0)
internal protocol FrameBodyBoundToConnection: FrameBodyProtocol {
    /// returns a header for `self` by inferring the flags from the given body.
    /// The stream id will always be `.connection`.
    func header() -> FrameHeader
}

/// a frame body that can be send or received on different streams and not only on `.connection`  (stream 0)
internal protocol FrameBodyBoundToStream: FrameBodyProtocol {
    /// returns a header for `self` by inferring the flags from the given body.
    /// - Parameter streamId: stream id for the header
    func header(withStreamId streamId: StreamID) -> FrameHeader
}


extension FrameBodyBoundToConnection {
    /// returns complete frame for `self`.
    /// The stream id will always be `.connection`.
    func frame() -> Frame {
        Frame(header: header(), body: body())
    }
}

extension FrameBodyBoundToStream {
    /// returns complete frame for `self`.
    /// - Parameter streamId: stream id for the header
    func frame(withStreamId streamId: StreamID) -> Frame {
        Frame(header: header(withStreamId: streamId), body: body())
    }
}

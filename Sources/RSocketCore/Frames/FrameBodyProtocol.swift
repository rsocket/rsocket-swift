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

internal protocol FragmentableFrameBody: FrameBodyProtocol {
    var fragmentsFollows: Bool { get set }
}

/// a frame body that can be send or received on different streams and not only on `.connection`  (stream 0)
internal protocol FrameBodyBoundToStream: FrameBodyProtocol {
    /// returns a header for `self` by inferring the flags from the given body.
    /// - Parameter streamId: stream id for the header
    /// - Parameter additionalFlags: additional flags which should be enabled
    func header(withStreamId streamId: StreamID) -> FrameHeader
}

/// a frame body that can only be send or received on stream `.connection` (stream 0)
internal protocol FrameBodyBoundToConnection: FrameBodyBoundToStream {
    /// returns a header for `self` by inferring the flags from the given body.
    /// The stream id will always be `.connection`.
    func header() -> FrameHeader
}

extension FrameBodyBoundToConnection {
    func header(withStreamId streamId: StreamID) -> FrameHeader {
        assert(streamId == .connection, "\(Self.self) should only be send on stream .connection (stream id 0)")
        return header()
    }
}

extension FrameBodyBoundToConnection {
    /// returns complete frame for `self`.
    /// The stream id will always be `.connection`.
    func asFrame() -> Frame {
        Frame(streamId: .connection, body: body())
    }
}

extension FrameBodyBoundToStream {
    /// returns complete frame for `self`.
    /// - Parameter streamId: stream id for the header
    func asFrame(withStreamId streamId: StreamID) -> Frame {
        Frame(streamId: streamId, body: body())
    }
}

extension FrameBodyProtocol {
    func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, to newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }
}

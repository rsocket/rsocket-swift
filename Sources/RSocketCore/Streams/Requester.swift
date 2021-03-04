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

internal final class Requester: FrameHandler {
    private let sendFrame: (Frame) -> Void
    private var streamIdGenerator: StreamIDGenerator
    private let maximumFrameSize: Int32
    private var activeStreams: [StreamID: StreamFragmenter] = [:]

    internal init(
        streamIdGenerator: StreamIDGenerator,
        maximumFrameSize: Int32,
        sendFrame: @escaping (Frame) -> Void
    ) {
        self.streamIdGenerator = streamIdGenerator
        self.maximumFrameSize = maximumFrameSize
        self.sendFrame = sendFrame
    }

    fileprivate func generateNewStreamId() -> StreamID {
        guard let id = streamIdGenerator.next() else {
            // TODO: handle stream id limit
            fatalError("stream id limit reached")
        }
        return id
    }

    internal func receiveInbound(frame: Frame) {
        guard let existingStreamAdapter = activeStreams[frame.header.streamId] else {
            // TODO: do not close connection for late frames
            closeConnection(with: .connectionError(message: "No active stream for given id"))
            return
        }
        existingStreamAdapter.receive(frame: frame)
        if frame.isTerminating {
            activeStreams.removeValue(forKey: frame.header.streamId)
        }
    }

    private func closeConnection(with error: Error) {
        let frame = ErrorFrameBody(error: error).frame(withStreamId: .connection)
        sendFrame(frame)
    }
}

extension Requester: StreamAdapterDelegate {
    internal func send(frame: Frame) {
        sendFrame(frame)
        /// TODO: we can not just terminate the connection if it is a terminating frame, because it may be a stream of type channel.
        /// In that case, we would terminate too early. We need to wait until both sides have been terminated.
//        if frame.isTerminating && frame.header.streamId != .connection {
//            activeStreams.removeValue(forKey: frame.header.streamId)
//        }
    }
}

extension Requester {
    /// Creates a stream that is already active
    @discardableResult
    public func requestStream(
        for type: StreamType,
        payload: Payload,
        createInput: (StreamOutput) -> StreamInput
    ) -> StreamOutput {
        let newId = generateNewStreamId()
        let adapter = StreamAdapter(id: newId)
        let fragmeter = StreamFragmenter(
            streamId: newId,
            maximumFrameSize: maximumFrameSize,
            adapter: adapter
        )
        fragmeter.delegate = self
        adapter.input = createInput(adapter)
        activeStreams[newId] = fragmeter
        sendRequest(id: newId, type: type, payload: payload)
        return adapter
    }

    private func sendRequest(id: StreamID, type: StreamType, payload: Payload) {
        let frame: Frame
        switch type {
        case .response:
            frame = RequestResponseFrameBody(payload: payload).frame(withStreamId: id)

        case .fireAndForget:
            frame = RequestFireAndForgetFrameBody(payload: payload).frame(withStreamId: id)

        case let .stream(initialRequestN):
            frame = RequestStreamFrameBody(
                initialRequestN: initialRequestN,
                payload: payload
            ).frame(withStreamId: id)

        case let .channel(initialRequestN, isCompleted):
            frame = RequestChannelFrameBody(
                isCompleted: isCompleted,
                initialRequestN: initialRequestN,
                payload: payload
            ).frame(withStreamId: id)
        }
        for fragment in frame.splitIntoFragmentsIfNeeded(maximumFrameSize: maximumFrameSize) {
            send(frame: fragment)
        }
    }
}

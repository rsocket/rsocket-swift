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
    private var activeStreams: [StreamID: StreamAdapter] = [:]

    internal init(
        streamIdGenerator: StreamIDGenerator,
        sendFrame: @escaping (Frame) -> Void
    ) {
        self.streamIdGenerator = streamIdGenerator
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
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: .connection)
        let frame = Frame(header: header, body: .error(body))
        sendFrame(frame)
    }
}

extension Requester: StreamAdapterDelegate {
    internal func send(frame: Frame) {
        // TODO: adjust MTU
        for fragment in frame.fragments(mtu: 64) {
            sendFrame(fragment)
        }
        /// TODO: we can not just terminate the connection if it is a terminating frame, because it may be a stream of type channel.
        /// In that case, we would terminate too early. We need to wait until both sides have been terminated.
//        if frame.isTerminating && frame.header.streamId != .connection {
//            activeStreams.removeValue(forKey: frame.header.streamId)
//        }
    }
}

extension Requester {
    func fireAndForget(payload: Payload) {
        let newId = generateNewStreamId()
        send(frame: RequestFireAndForgetFrameBody(
            fragmentsFollow: false,
            payload: payload
        ).frame(withStreamId: newId))
    }
    
    func requestResponse(payload: Payload, responderOutput: UnidirectionalStream) -> Cancellable {
        let newId = generateNewStreamId()
        let adapter = StreamAdapter(id: newId)
        adapter.delegate = self
        adapter.input = responderOutput
        activeStreams[newId] = adapter
        send(frame: RequestResponseFrameBody(
            fragmentsFollow: false,
            payload: payload
        ).frame(withStreamId: newId))
        
        return adapter
    }
    
    func stream(payload: Payload, initialRequestN: Int32, responderOutput: UnidirectionalStream) -> Subscription {
        let newId = generateNewStreamId()
        let adapter = StreamAdapter(id: newId)
        adapter.delegate = self
        adapter.input = responderOutput
        activeStreams[newId] = adapter
        send(frame: RequestStreamFrameBody(
            fragmentsFollow: false,
            initialRequestN: initialRequestN,
            payload: payload
        ).frame(withStreamId: newId))
        
        return adapter
    }
    
    func channel(
        payload: Payload,
        initialRequestN: Int32,
        isCompleted: Bool,
        responderOutput: UnidirectionalStream
    ) -> UnidirectionalStream {
        let newId = generateNewStreamId()
        let adapter = StreamAdapter(id: newId)
        adapter.delegate = self
        adapter.input = responderOutput
        activeStreams[newId] = adapter
        send(frame: RequestChannelFrameBody(
            fragmentsFollow: false,
            isCompleted: isCompleted,
            initialRequestN: initialRequestN,
            payload: payload
        ).frame(withStreamId: newId))
        
        return adapter
    }
}

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
import NIO

internal final class Requester {
    private let sendFrame: (Frame) -> Void
    private let eventLoop: EventLoop
    private var streamIdGenerator: StreamIDGenerator
    private var activeStreams: [StreamID: RequesterStream] = [:]

    internal init(
        streamIdGenerator: StreamIDGenerator,
        eventLoop: EventLoop,
        sendFrame: @escaping (Frame) -> Void
    ) {
        self.streamIdGenerator = streamIdGenerator
        self.eventLoop = eventLoop
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
    }

    private func closeConnection(with error: Error) {
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: .connection)
        let frame = Frame(header: header, body: .error(body))
        sendFrame(frame)
    }
}

extension Requester: StreamDelegate {
    internal func send(frame: Frame) {
        sendFrame(frame)
    }
    func terminate(streamId: StreamID) {
        activeStreams[streamId] = nil
        activeStreams.removeValue(forKey: streamId)
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
        let stream = RequesterStream(
            id: newId,
            terminationBehaviour: RequestResponseTerminationBehaviour(),
            input: responderOutput,
            delegate: self
        )
        activeStreams[newId] = stream
        
        send(frame: RequestResponseFrameBody(
            fragmentsFollow: false,
            payload: payload
        ).frame(withStreamId: newId))
        return ThreadSafeStreamAdapter(id: newId, eventLoop: eventLoop, delegate: stream)
    }
    
    func stream(payload: Payload, initialRequestN: Int32, responderOutput: UnidirectionalStream) -> Subscription {
        let newId = generateNewStreamId()
        let stream = RequesterStream(
            id: newId,
            terminationBehaviour: StreamTerminationBehaviour(),
            input: responderOutput,
            delegate: self
        )
        activeStreams[newId] = stream
        
        send(frame: RequestStreamFrameBody(
            fragmentsFollow: false,
            initialRequestN: initialRequestN,
            payload: payload
        ).frame(withStreamId: newId))
        return ThreadSafeStreamAdapter(id: newId, eventLoop: eventLoop, delegate: stream)
    }
    
    func channel(
        payload: Payload,
        initialRequestN: Int32,
        isCompleted: Bool,
        responderOutput: UnidirectionalStream
    ) -> UnidirectionalStream {
        let newId = generateNewStreamId()
        let stream = RequesterStream(
            id: newId,
            terminationBehaviour: ChannelTerminationBehaviour(),
            input: responderOutput,
            delegate: self
        )
        activeStreams[newId] = stream
        
        send(frame: RequestChannelFrameBody(
            fragmentsFollow: false,
            isCompleted: isCompleted,
            initialRequestN: initialRequestN,
            payload: payload
        ).frame(withStreamId: newId))
        return ThreadSafeStreamAdapter(id: newId, eventLoop: eventLoop, delegate: stream)
    }
}

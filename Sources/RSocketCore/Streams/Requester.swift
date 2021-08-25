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
import NIOCore

internal final class Requester {
    internal let encoding: ConnectionEncoding
    private let sendFrame: (Frame) -> Void
    private let eventLoop: EventLoop
    private var streamIdGenerator: StreamIDGenerator
    private var activeStreams: [StreamID: RequesterStream] = [:]
    private let lateFrameHandler: ((Frame) -> ())?

    internal init(
        streamIdGenerator: StreamIDGenerator,
        encoding: ConnectionEncoding,
        eventLoop: EventLoop,
        sendFrame: @escaping (Frame) -> Void,
        lateFrameHandler: ((Frame) -> ())? = nil
    ) {
        self.streamIdGenerator = streamIdGenerator
        self.encoding = encoding
        self.eventLoop = eventLoop
        self.sendFrame = sendFrame
        self.lateFrameHandler = lateFrameHandler
    }

    fileprivate func generateNewStreamId() -> StreamID {
        guard let id = streamIdGenerator.next() else {
            // TODO: handle stream id limit
            fatalError("stream id limit reached")
        }
        return id
    }

    internal func receiveInbound(frame: Frame) {
        let streamId = frame.streamId
        if streamId == .connection && frame.body.type == .error {
            activeStreams.values.forEach { $0.receive(frame: frame) }
            return
        }
        guard let existingStreamAdapter = activeStreams[streamId] else {
            lateFrameHandler?(frame)
            return
        }
        existingStreamAdapter.receive(frame: frame)
    }
}

extension Requester: StreamDelegate {
    internal func send(frame: Frame) {
        sendFrame(frame)
    }
    func terminate(streamId: StreamID) {
        activeStreams.removeValue(forKey: streamId)
    }
}

extension Requester: RSocket {
    func metadataPush(metadata: Data) {
        eventLoop.enqueueOrCallImmediatelyIfInEventLoop { [self] in
            send(frame: MetadataPushFrameBody(metadata: metadata).asFrame())
        }
    }

    func fireAndForget(payload: Payload) {
        eventLoop.enqueueOrCallImmediatelyIfInEventLoop { [self] in
            let newId = generateNewStreamId()
            send(frame: RequestFireAndForgetFrameBody(payload: payload).asFrame(withStreamId: newId))
        }
    }
    
    private func createAndAddStream<Body>(
        responderStream: UnidirectionalStream,
        terminationBehaviour: TerminationBehaviour,
        initialFrame body: Body
    ) -> ThreadSafeStreamAdapter where Body: FrameBodyBoundToStream {
        let adapter = ThreadSafeStreamAdapter(eventLoop: eventLoop)
        eventLoop.enqueueOrCallImmediatelyIfInEventLoop { [self] in
            let newId = generateNewStreamId()
            let stream = RequesterStream(
                id: newId,
                terminationBehaviour: terminationBehaviour,
                output: responderStream,
                delegate: self
            )
            activeStreams[newId] = stream
            adapter.id = newId
            adapter.delegate = stream
            send(frame: body.asFrame(withStreamId: newId))
        }
        
        return adapter
    }
    
    func requestResponse(payload: Payload, responderStream: UnidirectionalStream) -> Cancellable {
        return createAndAddStream(
            responderStream: responderStream,
            terminationBehaviour: RequestResponseTerminationBehaviour(),
            initialFrame: RequestResponseFrameBody(payload: payload)
        )
    }
    
    func stream(payload: Payload, initialRequestN: Int32, responderStream: UnidirectionalStream) -> Subscription {
        return createAndAddStream(
            responderStream: responderStream,
            terminationBehaviour: StreamTerminationBehaviour(),
            initialFrame: RequestStreamFrameBody(
                initialRequestN: initialRequestN,
                payload: payload
            )
        )
    }
    
    func channel(
        payload: Payload,
        initialRequestN: Int32,
        isCompleted: Bool,
        responderStream: UnidirectionalStream
    ) -> UnidirectionalStream {
        return createAndAddStream(
            responderStream: responderStream,
            terminationBehaviour: ChannelTerminationBehaviour(),
            initialFrame: RequestChannelFrameBody(
                isCompleted: isCompleted,
                initialRequestN: initialRequestN,
                payload: payload
            )
        )
    }
}

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

final internal class ResponderStream {
    private let streamId: StreamID
    fileprivate enum StreamKind {
        case requestResponse(Cancellable)
        case stream(Subscription)
        case channel(UnidirectionalStream)
    }
    private enum State {
        
        case waitingForInitialFragments(RSocket)
        case active(StreamKind)
    }
    private var state: State
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()
    private let eventLoop: EventLoop
    internal weak var delegate: StreamDelegate?
    
    internal init(
        streamId: StreamID,
        responderSocket: RSocket,
        eventLoop: EventLoop,
        delegate: StreamDelegate? = nil
    ) {
        self.streamId = streamId
        self.eventLoop = eventLoop
        self.delegate = delegate
        state = .waitingForInitialFragments(responderSocket)
    }

    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            switch state {
            case let .waitingForInitialFragments(socket):
                let adapter = ThreadSafeStreamAdapter(id: streamId, eventLoop: eventLoop, delegate: self)
                let streamKind: StreamKind?
                switch completeFrame.body {
                case let .requestFnf(body):
                    streamKind = nil
                    socket.fireAndForget(payload: body.payload)
                case let .requestResponse(body):
                    streamKind = .requestResponse(socket.requestResponse(
                        payload: body.payload,
                        responderOutput: adapter
                    ))
                case let .requestStream(body):
                    streamKind = .stream(socket.stream(
                        payload: body.payload,
                        initialRequestN: body.initialRequestN,
                        responderOutput: adapter
                    ))
                case let .requestChannel(body):
                    streamKind = .channel(socket.channel(
                        payload: body.payload,
                        initialRequestN: body.initialRequestN,
                        isCompleted: body.isCompleted,
                        responderOutput: adapter
                    ))
                default:
                    if !frame.header.flags.contains(.ignore) {
                        delegate?.send(frame: Error.connectionError(message: "Frame is not requesting new stream").asFrame(withStreamId: streamId))
                    }
                    return
                }
                if let streamKind = streamKind {
                    state = .active(streamKind)
                } else {
                    /// TODO: fire & forget implicitly closes the stream after the first message without any frames send back.
                    /// We need a way to tell the responder to remove `self` from its dictionary without sending a frame.
                }
            case let .active(adapter):
                if let error = adapter.forward(frame: frame) {
                    delegate?.send(frame: error.asFrame(withStreamId: streamId))
                }
            }

        case .incomplete:
            break

        case let .error(reason):
            if !frame.header.flags.contains(.ignore) {
                delegate?.send(frame: Error.connectionError(message: reason).asFrame(withStreamId: streamId))
            }
        }
    }
}

extension ResponderStream: StreamAdapterDelegate {
    func send(frame: Frame) {
        delegate?.send(frame: frame)
    }
}

extension ResponderStream.StreamKind {
    func forward(frame: Frame) -> Error? {
        switch self {
        case let .requestResponse(stream): return frame.forward(to: stream)
        case let .stream(stream): return frame.forward(to: stream)
        case let .channel(stream): return frame.forward(to: stream)
        }
    }
}

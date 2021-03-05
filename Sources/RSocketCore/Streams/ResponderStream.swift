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
    fileprivate enum StreamKind {
        case requestResponse(Cancellable)
        case stream(Subscription)
        case channel(UnidirectionalStream)
    }
    private enum State {
        
        case waitingForInitialFragments(RSocket)
        case active(StreamKind)
    }
    private let id: StreamID
    private var state: State
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()
    private var terminationBehaviour: TerminationBehaviour?
    private let eventLoop: EventLoop
    internal weak var delegate: StreamDelegate?
    
    internal init(
        id: StreamID,
        responderSocket: RSocket,
        eventLoop: EventLoop,
        delegate: StreamDelegate? = nil
    ) {
        self.id = id
        self.eventLoop = eventLoop
        self.delegate = delegate
        state = .waitingForInitialFragments(responderSocket)
    }

    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            switch state {
            case let .waitingForInitialFragments(socket):
                let adapter = ThreadSafeStreamAdapter(id: id, eventLoop: eventLoop, delegate: self)
                let streamKind: StreamKind?
                switch completeFrame.body {
                case let .requestFnf(body):
                    streamKind = nil
                    socket.fireAndForget(payload: body.payload)
                case let .requestResponse(body):
                    terminationBehaviour = RequestResponseTerminationBehaviour()
                    streamKind = .requestResponse(socket.requestResponse(
                        payload: body.payload,
                        responderStream: adapter
                    ))
                case let .requestStream(body):
                    terminationBehaviour = StreamTerminationBehaviour()
                    streamKind = .stream(socket.stream(
                        payload: body.payload,
                        initialRequestN: body.initialRequestN,
                        responderStream: adapter
                    ))
                case let .requestChannel(body):
                    terminationBehaviour = ChannelTerminationBehaviour()
                    streamKind = .channel(socket.channel(
                        payload: body.payload,
                        initialRequestN: body.initialRequestN,
                        isCompleted: body.isCompleted,
                        responderStream: adapter
                    ))
                default:
                    if !frame.header.flags.contains(.ignore) {
                        send(frame: Error.connectionError(message: "Frame is not requesting new stream").asFrame(withStreamId: id))
                    }
                    return
                }
                if let streamKind = streamKind {
                    state = .active(streamKind)
                    if terminationBehaviour?.shouldTerminateAfterRequesterSent(frame) == true {
                        delegate?.terminate(streamId: id)
                    }
                } else {
                    /// Fire & Forget does not need an active stream after receiving a request and needs to be terminated immediately
                    delegate?.terminate(streamId: id)
                }
            case let .active(adapter):
                if let error = adapter.receive(frame: frame) {
                    send(frame: error.asFrame(withStreamId: id))
                } else {
                    if terminationBehaviour?.shouldTerminateAfterRequesterSent(frame) == true {
                        delegate?.terminate(streamId: id)
                    }
                }
            }

        case .incomplete:
            break

        case let .error(reason):
            if !frame.header.flags.contains(.ignore) {
                send(frame: Error.canceled(message: reason).asFrame(withStreamId: id))
            }
        }
    }
}

extension ResponderStream: StreamAdapterDelegate {
    func send(frame: Frame) {
        delegate?.send(frame: frame)
        if terminationBehaviour?.shouldTerminateAfterResponderSent(frame) == true {
            delegate?.terminate(streamId: id)
        }
    }
}

extension ResponderStream.StreamKind {
    func receive(frame: Frame) -> Error? {
        switch self {
        case let .requestResponse(stream): return stream.receive(frame)
        case let .stream(stream): return stream.receive(frame)
        case let .channel(stream): return stream.receive(frame)
        }
    }
}

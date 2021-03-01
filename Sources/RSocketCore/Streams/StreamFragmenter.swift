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

internal class ResponderStreamAdapter {
    private var id: StreamID
    weak var delegate: StreamAdapterDelegate?
    
    internal init(id: StreamID, delegate: StreamAdapterDelegate? = nil) {
        self.id = id
        self.delegate = delegate
    }
}

extension ResponderStreamAdapter: UnidirectionalStream {
    internal func onNext(_ payload: Payload, isCompletion: Bool) {
        guard let delegate = delegate else { return }
        let body = PayloadFrameBody(
            fragmentsFollow: false,
            isCompletion: isCompletion,
            isNext: true,
            payload: payload
        )
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .payload(body))
        delegate.send(frame: frame)
    }

    internal func onError(_ error: Error) {
        guard let delegate = delegate else { return }
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .error(body))
        delegate.send(frame: frame)
    }

    internal func onComplete() {
        guard let delegate = delegate else { return }
        let body = PayloadFrameBody(
            fragmentsFollow: false,
            isCompletion: true,
            isNext: false,
            payload: .empty
        )
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .payload(body))
        delegate.send(frame: frame)
    }

    internal func onCancel() {
        guard let delegate = delegate else { return }
        let body = CancelFrameBody()
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .cancel(body))
        delegate.send(frame: frame)
    }

    internal func onRequestN(_ requestN: Int32) {
        guard let delegate = delegate else { return }
        let body = RequestNFrameBody(requestN: requestN)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .requestN(body))
        delegate.send(frame: frame)
    }

    internal func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard let delegate = delegate else { return }
        let body = ExtensionFrameBody(canBeIgnored: canBeIgnored, extendedType: extendedType, payload: payload)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .ext(body))
        delegate.send(frame: frame)
    }
}

internal class StreamFragmenter: StreamAdapterDelegate {
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
    internal weak var delegate: StreamAdapterDelegate?

    internal init(streamId: StreamID, responderSocket: RSocket) {
        self.streamId = streamId
        state = .waitingForInitialFragments(responderSocket)
    }

    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            switch state {
            case let .waitingForInitialFragments(socket):
                let adapter = ResponderStreamAdapter(id: streamId, delegate: self)
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
                        closeConnection(with: .connectionError(message: "Frame is not requesting new stream"))
                    }
                    return
                }
                if let streamKind = streamKind {
                    state = .active(streamKind)
                } else {
                    /// TODO: fire & forget implicitly closes the stream after the first message without any frames send back.
                    /// We need a way to tell the responder to remove the `self` from its dictionary without sending a frame.
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
                closeConnection(with: .connectionError(message: reason))
            }
        }
    }

    private func closeConnection(with error: Error) {
        guard let delegate = delegate else { return }
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: .connection)
        let frame = Frame(header: header, body: .error(body))
        delegate.send(frame: frame)
    }

    internal func send(frame: Frame) {
        guard let delegate = delegate else { return }
        // TODO: adjust MTU
        for fragment in frame.fragments(mtu: 64) {
            delegate.send(frame: fragment)
        }
    }
}

extension StreamFragmenter.StreamKind {
    func forward(frame: Frame) -> Error? {
        switch self {
        case let .requestResponse(stream): return frame.forward(to: stream)
        case let .stream(stream): return frame.forward(to: stream)
        case let .channel(stream): return frame.forward(to: stream)
        }
    }
}

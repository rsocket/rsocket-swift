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

internal class StreamFragmenter: StreamAdapterDelegate {
    private let streamId: StreamID
    private enum State {
        case waitingForInitialFragments(RSocket)
        case active(StreamAdapter)
    }
    private var state: State
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()
    internal weak var delegate: StreamAdapterDelegate?

    /// Called from requester
    internal init(streamId: StreamID, adapter: StreamAdapter) {
        self.streamId = streamId
        state = .active(adapter)
        adapter.delegate = self
    }

    /// Called from responder
    internal init(streamId: StreamID, responderSocket: RSocket) {
        self.streamId = streamId
        state = .waitingForInitialFragments(responderSocket)
    }

    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            switch state {
            case let .waitingForInitialFragments(socket):
                let adapter = StreamAdapter(id: streamId)
                adapter.delegate = self
                switch completeFrame.body {
                case let .requestResponse(body):
                    adapter.input = socket.requestResponse(payload: body.payload, input: adapter)

                case let .requestFnf(body):
                    adapter.input = socket.fireAndForget(payload: body.payload, input: adapter)

                case let .requestStream(body):
                    adapter.input = socket.stream(
                        payload: body.payload,
                        initialRequestN: body.initialRequestN,
                        input: adapter)
                case let .requestChannel(body):
                    adapter.input = socket.channel(
                        payload: body.payload,
                        initialRequestN: body.initialRequestN,
                        isCompleted: body.isCompleted,
                        input: adapter
                    )
                default:
                    if !frame.header.flags.contains(.ignore) {
                        closeConnection(with: .connectionError(message: "Frame is not requesting new stream"))
                    }
                    return
                }
                state = .active(adapter)

            case let .active(adapter):
                adapter.receive(frame: completeFrame)
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

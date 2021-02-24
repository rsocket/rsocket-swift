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
    private let maximumFrameSize: Int32
    private enum State {
        case waitingForInitialFragments((StreamType, Payload, StreamOutput) -> StreamInput)
        case active(StreamAdapter)
    }
    private var state: State
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()
    internal weak var delegate: StreamAdapterDelegate?

    /// Called from requester
    internal init(streamId: StreamID, maximumFrameSize: Int32, adapter: StreamAdapter) {
        self.streamId = streamId
        self.maximumFrameSize = maximumFrameSize
        state = .active(adapter)
        adapter.delegate = self
    }

    /// Called from responder
    internal init(streamId: StreamID, maximumFrameSize: Int32, createInput: @escaping (StreamType, Payload, StreamOutput) -> StreamInput) {
        self.streamId = streamId
        self.maximumFrameSize = maximumFrameSize
        state = .waitingForInitialFragments(createInput)
    }

    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            switch state {
            case let .waitingForInitialFragments(createInput):
                let adapter = StreamAdapter(id: streamId)
                adapter.delegate = self
                switch completeFrame.body {
                case let .requestResponse(body):
                    adapter.input = createInput(
                        .response,
                        body.payload,
                        adapter
                    )

                case let .requestFnf(body):
                    adapter.input = createInput(
                        .fireAndForget,
                        body.payload,
                        adapter
                    )

                case let .requestStream(body):
                    adapter.input = createInput(
                        .stream(initialRequestN: body.initialRequestN),
                        body.payload,
                        adapter
                    )

                case let .requestChannel(body):
                    adapter.input = createInput(
                        .channel(initialRequestN: body.initialRequestN, isCompleted: body.isCompleted),
                        body.payload,
                        adapter
                    )
                default:
                    if !frame.header.flags.contains(.ignore) {
                        closeConnection(with: .connectionError(message: "Frame is not requesting new stream"))
                    }
                    return
                }
                state = .active(adapter)

            case let .active(adapter):
                adapter.receiveInbound(frame: completeFrame)
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
        let frame = ErrorFrameBody(error: error).frame(withStreamId: .connection)
        delegate.send(frame: frame)
    }

    internal func send(frame: Frame) {
        guard let delegate = delegate else { return }
        for fragment in frame.splitIntoFragmentsIfNeeded(maximumFrameSize: maximumFrameSize) {
            delegate.send(frame: fragment)
        }
    }
}

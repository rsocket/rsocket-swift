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

internal final class Responder: FrameHandler {
    private let createStream: (StreamType, Payload, StreamOutput) -> StreamInput
    private let sendFrame: (Frame) -> Void
    private var activeStreams: [StreamID: StreamAdapter] = [:]

    internal init(
        createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput,
        sendFrame: @escaping (Frame) -> Void
    ) {
        self.createStream = createStream
        self.sendFrame = sendFrame
    }

    internal func receiveInbound(frame: Frame) {
        let streamId = frame.header.streamId
        if let existingStreamAdapter = activeStreams[streamId] {
            existingStreamAdapter.receive(frame: frame)
            return
        }
        switch frame.body {
        case .requestResponse, .requestFnf, .requestStream, .requestChannel:
            let adapter = StreamAdapter(
                delegate: self,
                createStream: createStream
            )
            adapter.streamId = streamId
            activeStreams[streamId] = adapter
            adapter.receive(frame: frame)
        default:
            // TODO: error unsupported frame type in this situation
            break
        }
    }
}

extension Responder: StreamAdapterDelegate {
    func register(adapter: StreamAdapter) -> StreamID {
        fatalError("StreamAdapter should not register itself at the responder.")
    }

    func send(frame: Frame) {
        sendFrame(frame)
    }

    func closeStream(id: StreamID) {
        activeStreams.removeValue(forKey: id)
    }

    func closeConnection(with error: Error) {
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: .connection)
        let frame = Frame(header: header, body: .error(body))
        sendFrame(frame)
        // TODO: close connection
    }
}

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
    private var activeStreams: [StreamID: StreamAdapter] = [:]

    internal init(sendFrame: @escaping (Frame) -> Void) {
        self.sendFrame = sendFrame
    }

    fileprivate func generateNewStreamId() -> StreamID {
        // TODO: generate ids
        .connection
    }

    internal func receiveInbound(frame: Frame) {
        guard let existingStreamAdapter = activeStreams[frame.header.streamId] else {
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
        sendFrame(frame)
        if frame.isTerminating && frame.header.streamId != .connection {
            activeStreams.removeValue(forKey: frame.header.streamId)
        }
    }
}

extension Requester {
    /// Creates a stream that is already active
    @discardableResult
    public func requestStream(
        for type: StreamType,
        payload: Payload,
        input: StreamInput
    ) -> StreamOutput {
        let newId = generateNewStreamId()
        let adapter = StreamAdapter(
            id: newId,
            delegate: self
        )
        adapter.input = input
        activeStreams[newId] = adapter
        sendRequest(id: newId, type: type, payload: payload)
        return adapter
    }

    private func sendRequest(id: StreamID, type: StreamType, payload: Payload) {
        let header: FrameHeader
        let body: FrameBody
        switch type {
        case .response:
            let requestResponseBody = RequestResponseFrameBody(
                fragmentsFollow: false,
                payload: payload
            )
            header = requestResponseBody.header(withStreamId: id)
            body = .requestResponse(requestResponseBody)

        case .fireAndForget:
            let fireAndForgetBody = RequestFireAndForgetFrameBody(
                fragmentsFollow: false,
                payload: payload
            )
            header = fireAndForgetBody.header(withStreamId: id)
            body = .requestFnf(fireAndForgetBody)

        case let .stream(initialRequestN):
            let streamBody = RequestStreamFrameBody(
                fragmentsFollow: false,
                initialRequestN: initialRequestN,
                payload: payload
            )
            header = streamBody.header(withStreamId: id)
            body = .requestStream(streamBody)

        case let .channel(initialRequestN, isCompleted):
            let channelBody = RequestChannelFrameBody(
                fragmentsFollow: false,
                isCompleted: isCompleted,
                initialRequestN: initialRequestN,
                payload: payload
            )
            header = channelBody.header(withStreamId: id)
            body = .requestChannel(channelBody)
        }
        let frame = Frame(header: header, body: body)
        // TODO: adjust MTU
        for fragment in frame.fragments(mtu: 64) {
            send(frame: fragment)
        }
    }
}

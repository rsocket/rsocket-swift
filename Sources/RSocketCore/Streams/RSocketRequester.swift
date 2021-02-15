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

internal final class RSocketRequester: RSocket {
    private var activeStreams: [StreamID: StreamAdapter] = [:]

    @discardableResult
    func createAdapter(
        for type: StreamType,
        payload: Payload,
        input: StreamInput
    ) -> StreamOutput {
        let streamId = generateNewStreamId()
        let adapter = StreamAdapter(
            streamId: streamId,
            createStream: { _, _, _ in input },
            sendFrame: { [weak self] in self?.sendOutbound(frame: $0) },
            terminate: { [weak self] in self?.activeStreams.removeValue(forKey: streamId) })
        activeStreams[streamId] = adapter
        // todo: payload fragmentation
        let header: FrameHeader
        let body: FrameBody
        switch type {
        case .response:
            let requestResponseBody = RequestResponseFrameBody(fragmentsFollow: false, payload: payload)
            header = requestResponseBody.header(withStreamId: streamId)
            body = .requestResponse(requestResponseBody)

        case .fireAndForget:
            let fireAndForgetBody = RequestFireAndForgetFrameBody(fragmentsFollow: false, payload: payload)
            header = fireAndForgetBody.header(withStreamId: streamId)
            body = .requestFnf(.init(fragmentsFollow: false, payload: payload))

        case let .stream(initialRequestN):
            let streamBody = RequestStreamFrameBody(fragmentsFollow: false, initialRequestN: initialRequestN, payload: payload)
            header = streamBody.header(withStreamId: streamId)
            body = .requestStream(.init(fragmentsFollow: false, initialRequestN: 0, payload: payload))

        case let .channel(initialRequestN, isCompleted):
            let channelBody = RequestChannelFrameBody(fragmentsFollow: false, isCompletion: false, initialRequestN: initialRequestN, payload: payload)
            header = channelBody.header(withStreamId: streamId)
            body = .requestChannel(.init(fragmentsFollow: false, isCompletion: isCompleted, initialRequestN: 0, payload: payload))
        }
        let frame = Frame(header: header, body: body)
        sendOutbound(frame: frame)
        return adapter
    }

    private func generateNewStreamId() -> StreamID {
        // TODO: generate ids
        .connection
    }

    func receiveInbound(frame: Frame) {
        guard let existingStreamAdapter = activeStreams[frame.header.streamId] else {
            // TODO: error no active stream for given id
            return
        }
        existingStreamAdapter.receive(frame: frame)
    }

    func sendOutbound(frame: Frame) {
        // TODO: send to multiplexer
    }
}

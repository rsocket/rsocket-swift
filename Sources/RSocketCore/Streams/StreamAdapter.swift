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

internal class StreamAdapter: StreamOutput {
    private let streamId: StreamID
    private let createStream: (StreamType, Payload, StreamOutput) -> StreamInput
    private let sendFrame: (Frame) -> Void
    private let terminate: () -> Void
    internal var stream: StreamInput?

    internal init(
        streamId: StreamID,
        createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput,
        sendFrame: @escaping (Frame) -> Void,
        terminate: @escaping () -> Void
    ) {
        self.streamId = streamId
        self.createStream = createStream
        self.sendFrame = sendFrame
        self.terminate = terminate
    }

    internal func receive(frame: Frame) {
        guard let stream = stream else {
            // stream not active yet
            switch frame.body {
            case let .requestResponse(body):
                // TODO: payload fragmentation
                stream = createStream(.response, body.payload, self)

            case let .requestFnf(body):
                // TODO: payload fragmentation
                stream = createStream(.fireAndForget, body.payload, self)

            case let .requestStream(body):
                // TODO: payload fragmentation
                stream = createStream(
                    .stream(initialRequestN: body.initialRequestN),
                    body.payload,
                    self
                )

            case let .requestChannel(body):
                // TODO: payload fragmentation
                stream = createStream(
                    .channel(initialRequestN: body.initialRequestN, isCompleted: body.isCompleted),
                    body.payload,
                    self
                )

            default:
                // TODO: error unsupported frame
                terminate()
            }
            return
        }

        // handle active stream
        switch frame.body {
        case let .requestN(body):
            stream.onRequestN(body.requestN)

        case .cancel:
            stream.onCancel()
            terminate()

        case let .payload(body):
            // TODO: fragmentation
            if body.isNext {
                stream.onNext(body.payload)
            }
            if body.isCompletion {
                stream.onComplete()
                terminate()
            }

        case let .error(body):
            stream.onError(body.error)
            terminate()

        case let .ext(body):
            stream.onExtension(
                extendedType: body.extendedType,
                payload: body.payload,
                canBeIgnored: body.canBeIgnored
            )

        default:
            // TODO: error unsupported frame
            terminate()
        }
    }

    internal func sendNext(_ payload: Payload, isCompletion: Bool) {
        // TODO: payload fragmentation
        let body = PayloadFrameBody(
            fragmentsFollow: false,
            isCompletion: isCompletion,
            isNext: true,
            payload: payload
        )
        let header = body.header(withStreamId: streamId)
        let frame = Frame(header: header, body: .payload(body))
        sendFrame(frame)
    }

    internal func sendError(_ error: Error) {
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: streamId)
        let frame = Frame(header: header, body: .error(body))
        sendFrame(frame)
    }

    internal func sendComplete() {
        let body = PayloadFrameBody(
            fragmentsFollow: false,
            isCompletion: true,
            isNext: false,
            payload: .empty
        )
        let header = body.header(withStreamId: streamId)
        let frame = Frame(header: header, body: .payload(body))
        sendFrame(frame)
        terminate()
    }

    internal func sendCancel() {
        let body = CancelFrameBody()
        let header = body.header(withStreamId: streamId)
        let frame = Frame(header: header, body: .cancel(body))
        sendFrame(frame)
    }

    internal func sendRequestN(_ requestN: Int32) {
        let body = RequestNFrameBody(requestN: requestN)
        let header = body.header(withStreamId: streamId)
        let frame = Frame(header: header, body: .requestN(body))
        sendFrame(frame)
    }

    internal func sendExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        let body = ExtensionFrameBody(canBeIgnored: canBeIgnored, extendedType: extendedType, payload: payload)
        let header = body.header(withStreamId: streamId)
        let frame = Frame(header: header, body: .ext(body))
        sendFrame(frame)
    }
}

extension Payload {
    static var empty: Payload { Payload(data: Data()) }
}

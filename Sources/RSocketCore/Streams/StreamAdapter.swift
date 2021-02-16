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
    private let closeStream: () -> Void
    private let closeConnection: (Error) -> Void
    internal var stream: StreamInput?
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()

    internal init(
        streamId: StreamID,
        createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput,
        sendFrame: @escaping (Frame) -> Void,
        closeStream: @escaping () -> Void,
        closeConnection: @escaping (Error) -> Void
    ) {
        self.streamId = streamId
        self.createStream = createStream
        self.sendFrame = sendFrame
        self.closeStream = closeStream
        self.closeConnection = closeConnection
    }

    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            process(frame: completeFrame)

        case .incomplete:
            break

        case let .error(reason: reason):
            // TODO: throw error with reason
            fatalError(reason)
        }
    }

    /// Process the **non-fragmented** frame
    private func process(frame: Frame) {
        guard let stream = stream else {
            startNewStream(with: frame)
            return
        }

        // handle active stream
        switch frame.body {
        case let .requestN(body):
            stream.onRequestN(body.requestN)

        case .cancel:
            stream.onCancel()
            closeStream()

        case let .payload(body):
            if body.isNext {
                stream.onNext(body.payload)
            }
            if body.isCompletion {
                stream.onComplete()
                closeStream()
            }

        case let .error(body):
            stream.onError(body.error)
            closeStream()

        case let .ext(body):
            stream.onExtension(
                extendedType: body.extendedType,
                payload: body.payload,
                canBeIgnored: body.canBeIgnored
            )

        default:
            if frame.header.flags.contains(.ignore) {
                closeStream()
            } else {
                closeConnection(.connectionError(message: "Invalid frame type for an active stream"))
            }
        }
    }

    private func startNewStream(with frame: Frame) {
        switch frame.body {
        case let .requestResponse(body):
            self.stream = createStream(.response, body.payload, weakStreamOutputs)

        case let .requestFnf(body):
            self.stream = createStream(.fireAndForget, body.payload, weakStreamOutputs)

        case let .requestStream(body):
            self.stream = createStream(
                .stream(initialRequestN: body.initialRequestN),
                body.payload,
                weakStreamOutputs
            )

        case let .requestChannel(body):
            self.stream = createStream(
                .channel(initialRequestN: body.initialRequestN, isCompleted: body.isCompleted),
                body.payload,
                weakStreamOutputs
            )

        default:
            if frame.header.flags.contains(.ignore) {
                closeStream()
            } else {
                closeConnection(.connectionError(message: "Invalid frame type for creating a new stream"))
            }
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
        closeStream()
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
        closeStream()
    }

    internal func sendCancel() {
        let body = CancelFrameBody()
        let header = body.header(withStreamId: streamId)
        let frame = Frame(header: header, body: .cancel(body))
        sendFrame(frame)
        closeStream()
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

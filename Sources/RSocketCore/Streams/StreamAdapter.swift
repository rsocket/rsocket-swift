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

internal protocol StreamAdapterDelegate: AnyObject {
    func register(adapter: StreamAdapter) -> StreamID
    func send(frame: Frame)
    func closeStream(id: StreamID)
    func closeConnection(with error: Error)
}

internal class StreamAdapter {
    internal weak var delegate: StreamAdapterDelegate?
    internal var streamId: StreamID?
    private var stream: StreamInput?
    private let createStream: (StreamType, Payload, StreamOutput) -> StreamInput

    private var fragmentedFrameAssembler = FragmentedFrameAssembler()

    internal init(
        delegate: StreamAdapterDelegate,
        createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput
    ) {
        self.delegate = delegate
        self.createStream = createStream
    }

    /// Receive frame from upstream (requester/responder)
    internal func receive(frame: Frame) {
        guard let streamId = streamId else {
            assertionFailure("StreamAdapter needs to be registered before receiving frames")
            return
        }
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            process(streamId: streamId, frame: completeFrame)

        case .incomplete:
            break

        case let .error(reason):
            if !frame.header.flags.contains(.ignore) {
                // TODO: Should we close the stream or just reset the state of fragmentedFrameAssembler?
                delegate?.closeStream(id: streamId)
            } else {
                delegate?.closeConnection(with: .connectionError(message: reason))
            }
        }
    }

    /// Process the **non-fragmented** frame
    private func process(streamId: StreamID, frame: Frame) {
        guard let stream = stream else {
            createNewStream(with: streamId, frame: frame)
            return
        }
        switch frame.body {
        case let .requestN(body):
            stream.onRequestN(body.requestN)

        case .cancel:
            stream.onCancel()
            delegate?.closeStream(id: streamId)

        case let .payload(body):
            if body.isNext {
                stream.onNext(body.payload)
            }
            if body.isCompletion {
                stream.onComplete()
                delegate?.closeStream(id: streamId)
            }

        case let .error(body):
            stream.onError(body.error)
            delegate?.closeStream(id: streamId)

        case let .ext(body):
            stream.onExtension(
                extendedType: body.extendedType,
                payload: body.payload,
                canBeIgnored: body.canBeIgnored
            )

        default:
            if frame.header.flags.contains(.ignore) {
                delegate?.closeStream(id: streamId)
            } else {
                delegate?.closeConnection(with: .connectionError(message: "Invalid frame type for an active stream"))
            }
        }
    }

    /// Creates a new stream for a given request frame (when `StreamAdapter` is instantiated by the responder)
    private func createNewStream(with id: StreamID, frame: Frame) {
        switch frame.body {
        case let .requestResponse(body):
            stream = createStream(.response, body.payload, weakStreamOutput)

        case let .requestFnf(body):
            stream = createStream(.fireAndForget, body.payload, weakStreamOutput)

        case let .requestStream(body):
            stream = createStream(
                .stream(initialRequestN: body.initialRequestN),
                body.payload,
                weakStreamOutput
            )

        case let .requestChannel(body):
            stream = createStream(
                .channel(initialRequestN: body.initialRequestN, isCompleted: body.isCompleted),
                body.payload,
                weakStreamOutput
            )

        default:
            if frame.header.flags.contains(.ignore) {
                delegate?.closeStream(id: id)
            } else {
                delegate?.closeConnection(with: .connectionError(message: "Invalid frame type for creating a new stream"))
            }
        }
    }
}

extension StreamAdapter: StreamOutput {
    internal func sendNext(_ payload: Payload, isCompletion: Bool) {
        // TODO: payload fragmentation
//        let body = PayloadFrameBody(
//            fragmentsFollow: false,
//            isCompletion: isCompletion,
//            isNext: true,
//            payload: payload
//        )
//        let header = body.header(withStreamId: streamId)
//        let frame = Frame(header: header, body: .payload(body))
//        sendFrame(frame)
    }

    internal func sendError(_ error: Error) {
//        let body = ErrorFrameBody(error: error)
//        let header = body.header(withStreamId: streamId)
//        let frame = Frame(header: header, body: .error(body))
//        sendFrame(frame)
//        closeStream()
    }

    internal func sendComplete() {
//        let body = PayloadFrameBody(
//            fragmentsFollow: false,
//            isCompletion: true,
//            isNext: false,
//            payload: .empty
//        )
//        let header = body.header(withStreamId: streamId)
//        let frame = Frame(header: header, body: .payload(body))
//        sendFrame(frame)
//        closeStream()
    }

    internal func sendCancel() {
//        let body = CancelFrameBody()
//        let header = body.header(withStreamId: streamId)
//        let frame = Frame(header: header, body: .cancel(body))
//        sendFrame(frame)
//        closeStream()
    }

    internal func sendRequestN(_ requestN: Int32) {
//        let body = RequestNFrameBody(requestN: requestN)
//        let header = body.header(withStreamId: streamId)
//        let frame = Frame(header: header, body: .requestN(body))
//        sendFrame(frame)
    }

    internal func sendExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
//        let body = ExtensionFrameBody(canBeIgnored: canBeIgnored, extendedType: extendedType, payload: payload)
//        let header = body.header(withStreamId: streamId)
//        let frame = Frame(header: header, body: .ext(body))
//        sendFrame(frame)
    }
}

extension Payload {
    static var empty: Payload { Payload(data: Data()) }
}

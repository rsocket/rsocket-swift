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
    func send(frame: Frame)
}

extension Frame {
    func fragments(mtu: Int32) -> [Frame] {
        // TODO
        []
    }
}

internal class StreamAdapter {
    private let id: StreamID
    internal weak var delegate: StreamAdapterDelegate?
    internal weak var input: StreamInput?
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()

    internal init(
        id: StreamID,
        delegate: StreamAdapterDelegate,
        input: StreamInput? = nil
    ) {
        self.id = id
        self.delegate = delegate
        self.input = input
    }

    internal func sendRequest(for type: StreamType, payload: Payload) {
        guard let delegate = delegate else { return }
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
            delegate.send(frame: fragment)
        }
    }

    /// Receive frame from upstream (requester/responder)
    internal func receive(frame: Frame) {
        switch fragmentedFrameAssembler.process(frame: frame) {
        case let .complete(completeFrame):
            process(frame: completeFrame)

        case .incomplete:
            break

        case let .error(reason):
            if !frame.header.flags.contains(.ignore) {
                closeConnection(with: .connectionError(message: reason))
            }
        }
    }

    /// Process the **non-fragmented** frame
    private func process(frame: Frame) {
        guard let input = input else {
            // input is deallocated so the active stream should be cancelled
            sendCancel()
            return
        }
        switch frame.body {
        case let .requestN(body):
            input.onRequestN(body.requestN)

        case .cancel:
            input.onCancel()

        case let .payload(body):
            if body.isNext {
                input.onNext(body.payload)
            }
            if body.isCompletion {
                input.onComplete()
            }

        case let .error(body):
            input.onError(body.error)

        case let .ext(body):
            input.onExtension(
                extendedType: body.extendedType,
                payload: body.payload,
                canBeIgnored: body.canBeIgnored
            )

        default:
            if !frame.header.flags.contains(.ignore) {
                closeConnection(with: .connectionError(message: "Invalid frame type for an active stream"))
            }
        }
    }

    private func closeConnection(with error: Error) {
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: .connection)
        let frame = Frame(header: header, body: .error(body))
        delegate?.send(frame: frame)
    }
}

extension StreamAdapter: StreamOutput {
    internal func sendNext(_ payload: Payload, isCompletion: Bool) {
        guard let delegate = delegate else { return }
        let body = PayloadFrameBody(
            fragmentsFollow: false,
            isCompletion: isCompletion,
            isNext: true,
            payload: payload
        )
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .payload(body))
        // TODO: adjust MTU
        for fragment in frame.fragments(mtu: 64) {
            delegate.send(frame: fragment)
        }
    }

    internal func sendError(_ error: Error) {
        guard let delegate = delegate else { return }
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .error(body))
        delegate.send(frame: frame)
    }

    internal func sendComplete() {
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

    internal func sendCancel() {
        guard let delegate = delegate else { return }
        let body = CancelFrameBody()
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .cancel(body))
        delegate.send(frame: frame)
    }

    internal func sendRequestN(_ requestN: Int32) {
        guard let delegate = delegate else { return }
        let body = RequestNFrameBody(requestN: requestN)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .requestN(body))
        delegate.send(frame: frame)
    }

    internal func sendExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard let delegate = delegate else { return }
        let body = ExtensionFrameBody(canBeIgnored: canBeIgnored, extendedType: extendedType, payload: payload)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .ext(body))
        delegate.send(frame: frame)
    }
}

extension Payload {
    static var empty: Payload { Payload(data: Data()) }
}

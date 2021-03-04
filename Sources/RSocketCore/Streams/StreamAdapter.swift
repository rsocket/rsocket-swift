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

internal protocol StreamAdapterDelegate: AnyObject {
    func send(frame: Frame)
}

internal class StreamAdapter {
    private let id: StreamID
    internal weak var delegate: StreamAdapterDelegate?
    internal weak var input: StreamInput?

    internal init(id: StreamID) {
        self.id = id
    }

    private func closeConnection(with error: Error) {
        guard let delegate = delegate else { return }
        let frame = ErrorFrameBody(error: error).frame(withStreamId: .connection)
        delegate.send(frame: frame)
    }
}

extension StreamAdapter: FrameHandler {
    internal func receiveInbound(frame: Frame) {
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
}

extension StreamAdapter: StreamOutput {
    internal func sendNext(_ payload: Payload, isCompletion: Bool) {
        guard let delegate = delegate else { return }
        let frame = PayloadFrameBody(
            isCompletion: isCompletion,
            isNext: true,
            payload: payload
        ).frame(withStreamId: id)
        delegate.send(frame: frame)
    }

    internal func sendError(_ error: Error) {
        guard let delegate = delegate else { return }
        let frame = ErrorFrameBody(error: error)
            .frame(withStreamId: id)
        delegate.send(frame: frame)
    }

    internal func sendComplete() {
        guard let delegate = delegate else { return }
        let frame = PayloadFrameBody(
            isCompletion: true,
            isNext: false,
            payload: .empty
        ).frame(withStreamId: id)
        delegate.send(frame: frame)
    }

    internal func sendCancel() {
        guard let delegate = delegate else { return }
        let frame = CancelFrameBody()
            .frame(withStreamId: id)
        delegate.send(frame: frame)
    }

    internal func sendRequestN(_ requestN: Int32) {
        guard let delegate = delegate else { return }
        let frame = RequestNFrameBody(requestN: requestN)
            .frame(withStreamId: id)
        delegate.send(frame: frame)
    }

    internal func sendExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard let delegate = delegate else { return }
        let frame = ExtensionFrameBody(
            canBeIgnored: canBeIgnored,
            extendedType: extendedType,
            payload: payload
        ).frame(withStreamId: id)
        delegate.send(frame: frame)
    }
}

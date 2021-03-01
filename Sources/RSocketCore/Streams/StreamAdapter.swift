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

extension Frame {
    internal func forward(to stream: Cancellable) -> Error? {
        switch body {
        case .cancel:
            stream.onCancel()
        default:
            if !header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(self.body.type) for an active cancelable")
            }
        }
        return nil
    }
    func forward(to stream: Subscription) -> Error? {
        switch body {
        case let .requestN(body):
            stream.onRequestN(body.requestN)
        case .cancel:
            stream.onCancel()
        default:
            if !header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(self.body.type) for an active subscription")
            }
        }
        return nil
    }
    func forward(to stream: UnidirectionalStream) -> Error? {
        switch body {
        case let .requestN(body):
            stream.onRequestN(body.requestN)

        case .cancel:
            stream.onCancel()

        case let .payload(body):
            if body.isNext {
                stream.onNext(body.payload, isCompletion: body.isCompletion)
            } else if body.isCompletion {
                stream.onComplete()
            }

        case let .error(body):
            stream.onError(body.error)

        case let .ext(body):
            stream.onExtension(
                extendedType: body.extendedType,
                payload: body.payload,
                canBeIgnored: body.canBeIgnored
            )
        default:
            if !header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(self.body.type) for an active unidirectional stream")
            }
        }
        return nil
    }
}

final internal class StreamAdapter {
    private let id: StreamID
    private var fragmentedFrameAssembler = FragmentedFrameAssembler()
    internal weak var delegate: StreamAdapterDelegate?
    internal weak var input: UnidirectionalStream?

    internal init(id: StreamID) {
        self.id = id
    }

    internal func receive(frame: Frame) {
        guard let input = input else {
            // input is deallocated so the active stream should be cancelled
            onCancel()
            return
        }
        switch fragmentedFrameAssembler.process(frame: frame) {
        case .incomplete:
            break
        case let .complete(completeFrame):
            if let error = completeFrame.forward(to: input) {
                delegate?.send(frame: error.asFrame(withStreamId: id))
            }
        case let .error(reason):
            if !frame.header.flags.contains(.ignore) {
                delegate?.send(frame: Error.connectionError(message: reason).asFrame(withStreamId: id))
            }
        }
    }
}

extension StreamAdapter: UnidirectionalStream {
    internal func onNext(_ payload: Payload, isCompletion: Bool) {
        guard let delegate = delegate else { return }
        let body = PayloadFrameBody(
            fragmentsFollow: false,
            isCompletion: isCompletion,
            isNext: true,
            payload: payload
        )
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .payload(body))
        delegate.send(frame: frame)
    }

    internal func onError(_ error: Error) {
        guard let delegate = delegate else { return }
        let body = ErrorFrameBody(error: error)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .error(body))
        delegate.send(frame: frame)
    }

    internal func onComplete() {
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

    internal func onCancel() {
        guard let delegate = delegate else { return }
        let body = CancelFrameBody()
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .cancel(body))
        delegate.send(frame: frame)
    }

    internal func onRequestN(_ requestN: Int32) {
        guard let delegate = delegate else { return }
        let body = RequestNFrameBody(requestN: requestN)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .requestN(body))
        delegate.send(frame: frame)
    }

    internal func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard let delegate = delegate else { return }
        let body = ExtensionFrameBody(canBeIgnored: canBeIgnored, extendedType: extendedType, payload: payload)
        let header = body.header(withStreamId: id)
        let frame = Frame(header: header, body: .ext(body))
        delegate.send(frame: frame)
    }
}

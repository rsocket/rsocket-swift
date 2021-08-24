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

import NIOCore

internal protocol StreamAdapterDelegate: AnyObject {
    func send(frame: Frame)
}

/// `ThreadSafeStreamAdapter` converts all stream events (e.g. onNext, onCancel, etc,) into frames with the given `id` and forwards them to `delegate` on `eventLoop`.
/// `ThreadSafeStreamAdapter` can be initialised without `id` and `delegate`.
/// In this case, the callee of the initialiser needs to make sure that setting `id` and `delegate` is at least scheduled on the given `eventLoop`.
/// Calls to e.g. onNext, onCancel, etc will submit a task to `eventLoop` which will require `id` to be set. Otherwise it will crash.
internal final class ThreadSafeStreamAdapter {
    internal var id: StreamID!
    private let eventLoop: EventLoop
    internal weak var delegate: StreamAdapterDelegate?
    
    internal init(id: StreamID? = nil, eventLoop: EventLoop, delegate: StreamAdapterDelegate? = nil) {
        self.id = id
        self.eventLoop = eventLoop
        self.delegate = delegate
    }
}

extension ThreadSafeStreamAdapter: UnidirectionalStream {
    private func send<Body>(_ body: Body) where Body: FrameBodyBoundToStream {
        eventLoop.enqueueOrCallImmediatelyIfInEventLoop { [self] in
            self.delegate?.send(frame: body.asFrame(withStreamId: self.id))
        }
    }
    
    internal func onNext(_ payload: Payload, isCompletion: Bool) {
        send(PayloadFrameBody(isCompletion: isCompletion, isNext: true, payload: payload))
    }
    internal func onError(_ error: Error) {
        send(ErrorFrameBody(error: error))
    }
    internal func onComplete() {
        send(PayloadFrameBody(isCompletion: true, isNext: false, payload: .empty))
    }
    internal func onCancel() {
        send(CancelFrameBody())
    }
    internal func onRequestN(_ requestN: Int32) {
        send(RequestNFrameBody(requestN: requestN))
    }
    internal func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        send(ExtensionFrameBody(canBeIgnored: canBeIgnored, extendedType: extendedType, payload: payload))
    }
}

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

internal class ThreadSafeStreamAdapter {
    private let id: StreamID
    private let eventLoop: EventLoop
    private weak var delegate: StreamAdapterDelegate?
    
    internal init(id: StreamID, eventLoop: EventLoop, delegate: StreamAdapterDelegate? = nil) {
        self.id = id
        self.eventLoop = eventLoop
        self.delegate = delegate
    }
}

extension ThreadSafeStreamAdapter: UnidirectionalStream {
    private func send<Body>(_ body: Body) where Body: FrameBodyBoundToStream {
        let frame = body.frame(withStreamId: id)
        if eventLoop.inEventLoop {
            delegate?.send(frame: frame)
        } else {
            eventLoop.execute { [weak delegate] in
                delegate?.send(frame: frame)
            }
        }
    }
    
    internal func onNext(_ payload: Payload, isCompletion: Bool) {
        send(PayloadFrameBody(fragmentsFollow: false, isCompletion: isCompletion, isNext: true, payload: payload))
    }
    internal func onError(_ error: Error) {
        send(ErrorFrameBody(error: error))
    }
    internal func onComplete() {
        send(PayloadFrameBody(fragmentsFollow: false, isCompletion: true, isNext: false, payload: .empty))
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

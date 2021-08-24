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

/// A stream which does not do anything.
fileprivate final class NoOpStream: UnidirectionalStream {
    func onNext(_ payload: Payload, isCompletion: Bool) {}
    func onError(_ error: Error) {}
    func onComplete() {}
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {}
    func onRequestN(_ requestN: Int32) {}
    func onCancel() {}
}


/// An RSocket which rejects all incoming requests (requestResponse, stream and channel) and ignores metadataPush and fireAndForget events.
internal struct DefaultRSocket: RSocket {
    func metadataPush(metadata: ByteBuffer) {}
    func fireAndForget(payload: Payload) {}
    func requestResponse(payload: Payload, responderStream: UnidirectionalStream) -> Cancellable {
        responderStream.onError(.rejected(message: "not implemented"))
        return NoOpStream()
    }
    func stream(payload: Payload, initialRequestN: Int32, responderStream: UnidirectionalStream) -> Subscription {
        responderStream.onError(.rejected(message: "not implemented"))
        return NoOpStream()
    }
    func channel(payload: Payload, initialRequestN: Int32, isCompleted: Bool, responderStream: UnidirectionalStream) -> UnidirectionalStream {
        responderStream.onError(.rejected(message: "not implemented"))
        return NoOpStream()
    }
}

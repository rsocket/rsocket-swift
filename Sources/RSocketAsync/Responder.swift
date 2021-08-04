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

#if compiler(>=5.5)
import RSocketCore
import Foundation

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
struct ResponderAdapter: RSocketCore.RSocket {
    var responder: RSocket
    let encoding: ConnectionEncoding 
    
    func metadataPush(metadata: Data) {
        responder.metadataPush(metadata: metadata)
    }

    func fireAndForget(payload: Payload) {
        responder.fireAndForget(payload: payload)
    }

    func requestResponse(
        payload: Payload, 
        responderStream: UnidirectionalStream
    ) -> Cancellable {
        let task = Task<Void, Never>.init(priority: nil) { 
            do {
                let response = try await responder.requestResponse(payload: payload)
                responderStream.onNext(response, isCompletion: true)
            } catch {
                responderStream.onError(Error.applicationError(message: error.localizedDescription))
            }
        }
        return RequestResponseResponder(task: task)
    }

    func stream(
        payload: Payload, 
        initialRequestN: Int32, 
        responderStream: UnidirectionalStream
    ) -> Subscription {
        let task = Task<Void, Never>.init(priority: nil) { 
            do {
                let stream = responder.requestStream(payload: payload)
                for try await responderPayload in stream {
                    responderStream.onNext(responderPayload, isCompletion: false)
                }
                responderStream.onComplete()
            } catch is CancellationError {
                responderStream.onCancel()
            } catch {
                responderStream.onError(Error.applicationError(message: error.localizedDescription))
            }
        }
        
        return RequestStreamResponder(task: task)
    }

    func channel(payload: Payload, initialRequestN: Int32, isCompleted: Bool, responderStream: UnidirectionalStream) -> UnidirectionalStream {
        let requesterStream = RequestChannelAsyncSequence()
        
        let task = Task<Void, Never>.init(priority: nil) { 
            do {
                let responderPayloads = responder.requestChannel(initialPayload: payload, payloadStream: requesterStream)
                for try await responderPayload in responderPayloads {
                    responderStream.onNext(responderPayload, isCompletion: false)
                }
                responderStream.onComplete()
            } catch is CancellationError {
                responderStream.onCancel()
            } catch {
                responderStream.onError(Error.applicationError(message: error.localizedDescription))
            }
        }
        requesterStream.task = task
        return requesterStream
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
fileprivate class RequestResponseResponder: Cancellable {
    private let task: Task<Void, Never>
    
    internal init(task: Task<Void, Never>) {
        self.task = task
    }
    
    deinit {
        task.cancel()
    }
    
    func onCancel() {
        task.cancel()
    }
    
    func onError(_ error: Error) {
        // TODO: Can a request actually send an error? If yes, we should probably do something with the error
        task.cancel()
    }
    
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        assertionFailure("\(Self.self) does not support \(#function)")
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
fileprivate class RequestStreamResponder: Subscription {
    private let task: Task<Void, Never>
    
    internal init(task: Task<Void, Never>) {
        self.task = task
    }
    
    deinit {
        task.cancel()
    }
    
    func onCancel() {
        task.cancel()
    }
    
    func onError(_ error: Error) {
        // TODO: Can a stream actually send an error? If yes, we should probably do something with the error
        task.cancel()
    }
    
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        assertionFailure("\(Self.self) does not support \(#function)")
    }
    
    func onRequestN(_ requestN: Int32) {
        assertionFailure("\(Self.self) does not support \(#function)")
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
fileprivate class RequestChannelAsyncSequence: AsyncSequence, UnidirectionalStream {
    typealias AsyncIterator = AsyncThrowingStream<Payload, Swift.Error>.AsyncIterator
    typealias Element = Payload
    
    private var iterator: AsyncThrowingStream<Payload, Swift.Error>.AsyncIterator!
    private var continuation: AsyncThrowingStream<Payload, Swift.Error>.Continuation!
    
    internal var task: Task<Void, Never>?
    
    internal init() {
        let sequence = AsyncThrowingStream(Payload.self, bufferingPolicy: .unbounded) { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable [weak self] (reason) in
                // TODO: `task` is not safe to access here because we set it late, after we give `self` to user code
                // but just adding a lock is not enough because we could be terminated before `task` is even set and we then need to cancel `task` after it is set
                // I hope we find a better solution. Maybe we can access the current task from within the `Task.init` closure which would solve both problems mentioned above
                // UPDATE: Looks like it will be possible. The documentation of `withUnsafeCurrentTask(body:)` says that `UnsafeCurrentTask` has get a `task` property. But it does currently (Xcode 12 Beta 3) not have it.
                switch reason {
                case let .finished(.some(error)):
                    if error is CancellationError {
                        return
                    }
                    // only in the error case we cancel task
                    self?.task?.cancel()
                case .finished(nil): break
                case .cancelled: break
                @unknown default: break
                }
            }
        }
        iterator = sequence.makeAsyncIterator()
    }
    
    deinit {
        task?.cancel()
        continuation.finish(throwing: CancellationError())
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        iterator
    }
    
    func onNext(_ payload: Payload, isCompletion: Bool) {
        continuation.yield(payload)
        if isCompletion {
            continuation.finish()
        }
    }
    
    func onComplete() {
        continuation.finish()
    }
    
    func onCancel() {
        continuation.finish(throwing: CancellationError())
    }
    
    func onError(_ error: Error) {
        continuation.finish(throwing: error)
        task?.cancel()
    }
    
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        assertionFailure("\(Self.self) does not support \(#function)")
    }
    
    func onRequestN(_ requestN: Int32) {
        assertionFailure("\(Self.self) does not support \(#function)")
    }
}

#endif

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
import Foundation
import NIO
import RSocketCore
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension RequesterRSocket {
    public func callAsFunction<Metadata>(_ metadataPush: MetadataPush<Metadata>, metadata: Metadata) throws {
        self.metadataPush(metadata: try metadataPush.encoder.encode(metadata))
    }

    public func callAsFunction<Request>(_ fireAndForget: FireAndForget<Request>, request: Request) throws {
        var encoder = fireAndForget.encoder
        self.fireAndForget(payload: try encoder.encode(request, encoding: encoding))
    }
    
    public func callAsFunction<Request, Response>(
        _ requestResponse: RequestResponse<Request, Response>,
        request: Request
    ) async throws -> Response {
        var encoder = requestResponse.encoder
        let response = try await self.requestResponse(payload: encoder.encode(request, encoding: encoding))
        var decoder = requestResponse.decoder
        return try decoder.decode(response, encoding: encoding)
    }
    
    public func callAsFunction<Request, Response>(
        _ requestStream: RequestStream<Request, Response>,
        request: Request
    ) throws -> AsyncThrowingMapSequence<AsyncThrowingStream<Payload, Swift.Error>, Response> {
        /// TODO: this method should not throw but rather the async sequence should throw an error
        /// TODO: result type of this method should be an opaque result type with where clause  (e.g. `some AsyncSequence where _.Element == Response`)  once they are available in Swift
        var encoder = requestStream.encoder
        var decoder = requestStream.decoder
        let a = self.requestStream(payload: try encoder.encode(request, encoding: encoding)).map { response throws -> Response in
            try decoder.decode(response, encoding: encoding)
        }
        return a
    }
    
    public func callAsFunction<Request, Response, Producer>(
        _ requestChannel: RequestChannel<Request, Response>,
        initialRequest: Request,
        producer: Producer?
    ) throws -> AsyncThrowingMapSequence<AsyncThrowingStream<Payload, Swift.Error>, Response> 
    where Producer: AsyncSequence, Producer.Element == Request {
        /// TODO: this method should not throw but rather the async sequence should throw an error
        /// TODO: result type of this method should be an opaque result type with where clause  (e.g. `some AsyncSequence where _.Element == Response`)  once they are available in Swift
        var encoder = requestChannel.encoder
        var decoder = requestChannel.decoder
        
        return self.requestChannel(
            initialPayload: try encoder.encode(initialRequest, encoding: encoding), 
            payloadStream: producer?.map { try encoder.encode($0, encoding: encoding) }
        ).map {
            try decoder.decode($0, encoding: encoding)
        }
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct RequesterRSocket {
    private let requester: RSocketCore.RSocket
    
    internal var encoding: ConnectionEncoding { requester.encoding }
    public init(requester: RSocketCore.RSocket) {
        self.requester = requester
    }
    internal func metadataPush(metadata: Data) {
        requester.metadataPush(metadata: metadata)
    }
    internal func fireAndForget(payload: Payload) {
        requester.fireAndForget(payload: payload)
    }
    internal func requestResponse(payload: Payload) async throws -> Payload {
        struct RequestResponseOperator: UnidirectionalStream {
            var continuation: CheckedContinuation<Payload, Swift.Error>
            func onNext(_ payload: Payload, isCompletion: Bool) {
                assert(isCompletion)
                continuation.resume(returning: payload)
            }
            
            func onComplete() {
                assertionFailure("request response does not support \(#function)")
            }
            
            func onRequestN(_ requestN: Int32) {
                assertionFailure("request response does not support \(#function)")
            }
            
            func onCancel() {
                continuation.resume(throwing: Error.canceled(message: "onCancel"))
            }
            
            func onError(_ error: Error) {
                continuation.resume(throwing: error)
            }
            
            func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
                assertionFailure("request response does not support \(#function)")
            }
        }
        var cancelable: Cancellable?
        defer { cancelable?.onCancel() }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Payload, Swift.Error>) in
            let stream = RequestResponseOperator(continuation: continuation)
            cancelable = requester.requestResponse(payload: payload, responderStream: stream)
        }
    }
    
    internal func requestStream(payload: Payload) -> AsyncThrowingStream<Payload, Swift.Error> {
        AsyncThrowingStream(Payload.self, bufferingPolicy: .unbounded) { continuation in
            let adapter = AsyncStreamAdapter(continuation: continuation)
            let subscription = requester.stream(payload: payload, initialRequestN: .max, responderStream: adapter)
            continuation.onTermination = { @Sendable (reason: AsyncThrowingStream<Payload, Swift.Error>.Continuation.Termination) -> Void in
                switch reason {
                case .cancelled:
                    subscription.onCancel()
                case .finished: break
                // TODO: `Termination` should probably be @frozen so we do not have to deal with the @unknown default case
                @unknown default: break
                }
            }
        }
    }
    
    internal func requestChannel<PayloadSequence>(
        initialPayload: Payload, 
        payloadStream: PayloadSequence?
    ) -> AsyncThrowingStream<Payload, Swift.Error> where PayloadSequence: AsyncSequence, PayloadSequence.Element == Payload {
        AsyncThrowingStream(Payload.self, bufferingPolicy: .unbounded) { continuation in
            let adapter = AsyncStreamAdapter(continuation: continuation)
            let channel = requester.channel(
                payload: initialPayload, 
                initialRequestN: .max, 
                isCompleted: payloadStream == nil, 
                responderStream: adapter
            )
            
            let task = Task.detached {
                guard let payloadStream = payloadStream else { return }
                do {
                    for try await payload in payloadStream {
                        channel.onNext(payload, isCompletion: false)
                    }
                    channel.onComplete()
                } catch is CancellationError {
                    channel.onCancel()
                } catch {
                    channel.onError(Error.applicationError(message: error.localizedDescription))
                }
            }
            
            continuation.onTermination = { @Sendable (reason: AsyncThrowingStream<Payload, Swift.Error>.Continuation.Termination) -> Void in
                switch reason {
                case .cancelled:
                    channel.onCancel()
                    task.cancel()
                case .finished: break
                // TODO: `Termination` should probably be @frozen so we do not have to deal with the @unknown default case
                @unknown default: break
                }
            }
        }
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
internal final class AsyncStreamAdapter: UnidirectionalStream {
    private var continuation: AsyncThrowingStream<Payload, Swift.Error>.Continuation
    init(continuation: AsyncThrowingStream<Payload, Swift.Error>.Continuation) {
        self.continuation = continuation
    }
    internal func onNext(_ payload: Payload, isCompletion: Bool) {
        continuation.yield(payload)
        if isCompletion {
            continuation.finish()
        }
    }

    internal func onComplete() {
        continuation.finish()
    }

    internal func onRequestN(_ requestN: Int32) {
        assertionFailure("request stream does not support \(#function)")
    }

    internal func onCancel() {
        continuation.finish()
    }

    internal func onError(_ error: Error) {
        continuation.yield(with: .failure(error))
    }

    internal func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        assertionFailure("request stream does not support \(#function)")
    }
}

#endif

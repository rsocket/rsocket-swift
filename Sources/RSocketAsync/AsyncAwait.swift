#if compiler(>=5.5)
import Foundation
import NIO
import RSocketCore
import _Concurrency
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public protocol RSocket {
    func metadataPush(metadata: Data)
    func fireAndForget(payload: Payload)
    func requestResponse(payload: Payload) async throws -> Payload
    func requestStream(payload: Payload) -> AsyncThrowingStream<Payload, Swift.Error>
    func requestChannel<PayloadSequence>(
        initialPayload: Payload, 
        payloadStream: PayloadSequence
    ) -> AsyncThrowingStream<Payload, Swift.Error> 
    where PayloadSequence: AsyncSequence, PayloadSequence.Element == Payload
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct RequesterAdapter: RSocket {
    private let requester: RSocketCore.RSocket
    public init(requester: RSocketCore.RSocket) {
        self.requester = requester
    }
    public func metadataPush(metadata: Data) {
        requester.metadataPush(metadata: metadata)
    }
    public func fireAndForget(payload: Payload) {
        requester.fireAndForget(payload: payload)
    }
    public func requestResponse(payload: Payload) async throws -> Payload {
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
    
    public func requestStream(payload: Payload) -> AsyncThrowingStream<Payload, Swift.Error> {
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
    
    public func requestChannel<PayloadSequence>(
        initialPayload: Payload, 
        payloadStream: PayloadSequence
    ) -> AsyncThrowingStream<Payload, Swift.Error> where PayloadSequence: AsyncSequence, PayloadSequence.Element == Payload {
        AsyncThrowingStream(Payload.self, bufferingPolicy: .unbounded) { continuation in
            let adapter = AsyncStreamAdapter(continuation: continuation)
            let channel = requester.channel(
                payload: initialPayload, 
                initialRequestN: .max, 
                isCompleted: false, 
                responderStream: adapter
            )
            
            let task = Task.detached {
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

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct AsyncClient {
    private let coreClient: RSocketCore.CoreClient

    public var requester: RSocket { RequesterAdapter(requester: coreClient.requester) }

    public init(_ coreClient: RSocketCore.CoreClient) {
        self.coreClient = coreClient
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension RSocketCore.ClientBootstrap where Client == CoreClient, Responder == RSocketCore.RSocket  {
    public func connect(to endpoint: Transport.Endpoint, payload: Payload) async throws -> AsyncClient {
        AsyncClient(try await connect(to: endpoint, payload: payload, responder: nil).get())
    }
}
#endif

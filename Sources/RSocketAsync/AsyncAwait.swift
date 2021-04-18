#if compiler(>=5.4) && $AsyncAwait
import RSocketCore
import _Concurrency
import NIO
import _NIOConcurrency

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public protocol RSocket {
    func requestResponse(payload: Payload) async throws -> Payload
    func requestStream(payload: Payload) -> AsyncStreamSequence
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct RequesterAdapter: RSocket {
    private let requester: RSocketCore.RSocket
    public init(requester: RSocketCore.RSocket) {
        self.requester = requester
    }
    public func requestResponse(payload: Payload) async throws -> Payload {
        struct RequestResponseOperator: UnidirectionalStream {
            var continuation: UnsafeContinuation<Payload, Swift.Error>
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
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Payload, Swift.Error>) in
            let stream = RequestResponseOperator(continuation: continuation)
            cancelable = requester.requestResponse(payload: payload, responderStream: stream)
        }
    }
    
    public func requestStream(payload: Payload) -> AsyncStreamSequence {
        AsyncStreamSequence(payload: payload, requester: requester)
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct AsyncStreamSequence: AsyncSequence {
    public typealias AsyncIterator = AsyncStreamIterator
    
    public typealias Element = Payload
    
    fileprivate init(payload: Payload, requester: RSocketCore.RSocket) {
        self.payload = payload
        self.requester = requester
    }
    private var payload: Payload
    private var requester: RSocketCore.RSocket
    public func makeAsyncIterator() -> AsyncStreamIterator {
        let stream = AsyncStreamIterator()
        stream.subscription = requester.stream(payload: payload, initialRequestN: 0, responderStream: stream)
        return stream
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public final class AsyncStreamIterator: AsyncIteratorProtocol, UnidirectionalStream {
    fileprivate var subscription: Subscription! = nil
    private var yieldingContinuation = YieldingContinuation<Payload?, Swift.Error>()
    
    public func onNext(_ payload: Payload, isCompletion: Bool) {
        _ = yieldingContinuation.yield(payload)
        if isCompletion {
            _ = yieldingContinuation.yield(nil)
        }
    }
    
    public func onComplete() {
        _ = yieldingContinuation.yield(nil)
    }
    
    public func onRequestN(_ requestN: Int32) {
        assertionFailure("request stream does not support \(#function)")
    }
    
    public func onCancel() {
        _ = yieldingContinuation.yield(nil)
    }
    
    public func onError(_ error: Error) {
        _ = yieldingContinuation.yield(throwing: error)
    }
    
    public func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        assertionFailure("request stream does not support \(#function)")
    }
    public func next() async throws -> Payload? {
        subscription.onRequestN(1)
        return try await yieldingContinuation.next()
    }
    deinit {
        subscription.onCancel()
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
    public func connect(to endpoint: Transport.Endpoint) async throws -> AsyncClient {
        AsyncClient(try await connect(to: endpoint, responder: nil).get())
    }
}
#endif

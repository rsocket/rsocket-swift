#if compiler(>=5.5) && $AsyncAwait
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
    func requestStream(payload: Payload) -> AsyncStreamSequence
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
actor BufferedContinuation<Element, Error: Swift.Error> {
    typealias Item = Result<Element, Error>
    let continuation = YieldingContinuation(yielding: Item.self)
    var buffer = [Item]()
    
    public func push(result: Item) async {
        if !continuation.yield(result) {
            buffer.append(result)
        }
    }
    public func push(_ element: Element) async {
        await push(result: .success(element))
    }
    public func push(throwing error: Error) async {
        await push(result: .failure(error))
    }
    
    public func pop() async throws -> Element {
        if buffer.count > 0 {
            return try buffer.removeFirst().get()
        }
        return try await continuation.next().get()
    }
    
    public func popAsResult() async -> Item {
        if buffer.count > 0 {
            return buffer.removeFirst()
        }
        return await continuation.next()
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public final class AsyncStreamIterator: AsyncIteratorProtocol, UnidirectionalStream {
    fileprivate var subscription: Subscription! = nil
    private var yieldingContinuation = BufferedContinuation<Payload?, Swift.Error>()
    private var isCompleted = false
    public func onNext(_ payload: Payload, isCompletion: Bool) {
        detach { [self] in
            await yieldingContinuation.push(payload)
            if isCompletion {
                await yieldingContinuation.push(nil)
            }
        }
    }
    
    public func onComplete() {
        detach { [self] in
            await yieldingContinuation.push(nil)
        }
    }
    
    public func onRequestN(_ requestN: Int32) {
        assertionFailure("request stream does not support \(#function)")
    }
    
    public func onCancel() {
        detach { [self] in
            await yieldingContinuation.push(nil)
        }
    }
    
    public func onError(_ error: Error) {
        detach { [self] in
            await yieldingContinuation.push(throwing: error)
        }
    }
    
    public func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        assertionFailure("request stream does not support \(#function)")
    }
    public func next() async throws -> Payload? {
        guard !isCompleted else { return nil }
        subscription.onRequestN(1)
        let value = await yieldingContinuation.popAsResult()
        switch value {
        case .failure, .success(.none):
            isCompleted = true
        default: break
        }
        return try value.get()
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

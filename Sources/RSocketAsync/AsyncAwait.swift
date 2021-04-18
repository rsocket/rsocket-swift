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
    private let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    public init(requester: RSocketCore.RSocket) {
        self.requester = requester
    }
    public func requestResponse(payload: Payload) async throws -> Payload {
        struct RequestResponseOperator: UnidirectionalStream {
            var promise: EventLoopPromise<Payload>
            func onNext(_ payload: Payload, isCompletion: Bool) {
                assert(isCompletion)
                promise.succeed(payload)
            }
            
            func onComplete() {
                assertionFailure("request response does not support \(#function)")
            }
            
            func onRequestN(_ requestN: Int32) {
                assertionFailure("request response does not support \(#function)")
            }
            
            func onCancel() {
                promise.fail(Error.canceled(message: "onCancel"))
            }
            
            func onError(_ error: Error) {
                promise.fail(error)
            }
            
            func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
                assertionFailure("request response does not support \(#function)")
            }
        }
        let promise = eventLoop.next().makePromise(of: Payload.self)
        let stream = RequestResponseOperator(promise: promise)
        _ = requester.requestResponse(payload: payload, responderStream: stream)
        return try await promise.futureResult.get()
    }
    
    public func requestStream(payload: Payload) -> AsyncStreamSequence {
        AsyncStreamSequence(payload: payload, requester: requester, eventLoop: eventLoop.next())
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct AsyncStreamSequence: AsyncSequence {
    public typealias AsyncIterator = AsyncStreamIterator
    
    public typealias Element = Payload
    
    fileprivate init(payload: Payload, requester: RSocketCore.RSocket, eventLoop: EventLoop) {
        self.payload = payload
        self.requester = requester
        self.eventLoop = eventLoop
    }
    private var payload: Payload
    private var requester: RSocketCore.RSocket
    private var eventLoop: EventLoop
    public func makeAsyncIterator() -> AsyncStreamIterator {
        let stream = AsyncStreamIterator(eventLoop: eventLoop)
        stream.subscription = requester.stream(payload: payload, initialRequestN: 0, responderStream: stream)
        return stream
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public final class AsyncStreamIterator: AsyncIteratorProtocol, UnidirectionalStream {
    fileprivate init(
        eventLoop: EventLoop
    ) {
        self.eventLoop = eventLoop
    }
    
    private enum Event {
        case next(Payload, isCompletion: Bool)
        case error(Error)
        case complete
        case cancel
    }
    private var eventLoop: EventLoop
    private var event: EventLoopPromise<Event>? = nil
    private var isCompleted: Bool = false
    fileprivate var subscription: Subscription! = nil
    public func onNext(_ payload: Payload, isCompletion: Bool) {
        eventLoop.execute { [self] in
            assert(event != nil)
            event?.succeed(.next(payload, isCompletion: isCompletion))
        }
        
    }
    
    public func onComplete() {
        eventLoop.execute {  [self] in
            assert(event != nil)
            event?.succeed(.complete)
        }
    }
    
    public func onRequestN(_ requestN: Int32) {
        assertionFailure("request response does not support \(#function)")
    }
    
    public func onCancel() {
        eventLoop.execute {  [self] in
            assert(event != nil)
            event?.succeed(.cancel)
        }
    }
    
    public func onError(_ error: Error) {
        eventLoop.execute { [self] in
            assert(event != nil)
            event?.succeed(.error(error))
        }
    }
    
    public func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        assertionFailure("request response does not support \(#function)")
    }
    public func next() async throws -> Payload? {
        let p = eventLoop.makePromise(of: Optional<Payload>.self)
        p.completeWithAsync { [self] in
            guard !isCompleted else { return nil }
            assert(event == nil)
            let promise = eventLoop.makePromise(of: Event.self)
            event = promise
            subscription.onRequestN(1)
            let result = try await promise.futureResult.get()
            event = nil
            switch result {
            case let .next(payload, isCompletion):
                self.isCompleted = isCompletion
                return payload
            case .complete:
                self.isCompleted = true
                return nil
            case .cancel:
                self.isCompleted = true
                return nil
            case let .error(error):
                self.isCompleted = true
                throw error
            }
        }
        return try await p.futureResult.get()
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

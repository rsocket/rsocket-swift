import XCTest
import NIO
import ReactiveSwift
@testable import RSocketCore
import RSocketTestUtilities
@testable import RSocketReactiveSwift

struct TestDemultiplexer {
    let router: DemultiplexerRouter
    let requester: Requester
    let responder: Responder
    
    internal init(connectionSide: ConnectionRole, requester: Requester, responder: Responder) {
        self.router = .init(connectionSide: connectionSide)
        self.requester = requester
        self.responder = responder
    }
    
    func receiveFrame(frame: Frame) {
        let route = router.route(for: frame.header.streamId, type: frame.header.type)
        if route.contains(.connection) {
            XCTFail("connection message not expected \(frame)")
        }
        if route.contains(.requester) {
            requester.receiveInbound(frame: frame)
        }
        if route.contains(.responder) {
            responder.receiveInbound(frame: frame)
        }
    }
}

extension TestDemultiplexer {
    static func pipe(
        serverResponder: RSocketCore.RSocket,
        clientResponder: RSocketCore.RSocket
    ) -> (eventLoop: EmbeddedEventLoop, server: TestDemultiplexer, client: TestDemultiplexer) {
        var client: TestDemultiplexer!
        let eventLoop = EmbeddedEventLoop()
        let server = TestDemultiplexer(
            connectionSide: .server,
            requester: .init(streamIdGenerator: .server, eventLoop: eventLoop, sendFrame: { frame in
                client.receiveFrame(frame: frame)
            }),
            responder: .init(responderSocket: serverResponder, eventLoop: eventLoop, sendFrame: { frame in
                client.receiveFrame(frame: frame)
            }))
        client = TestDemultiplexer(
            connectionSide: .client,
            requester: .init(streamIdGenerator: .client, eventLoop: eventLoop, sendFrame: { frame in
                server.receiveFrame(frame: frame)
            }),
            responder: .init(responderSocket: clientResponder, eventLoop: eventLoop, sendFrame: { frame in
                server.receiveFrame(frame: frame)
            }))
        return (eventLoop, server, client!)
    }
}

func setup(
    server: RSocketReactiveSwift.RSocket? = nil,
    client: RSocketReactiveSwift.RSocket? = nil
) -> (eventLoop: EmbeddedEventLoop, server: TestDemultiplexer, client: TestDemultiplexer) {
    let (eventLoop, server, client) = TestDemultiplexer.pipe(
        serverResponder: ResponderAdapter(responder: server),
        clientResponder: ResponderAdapter(responder: client))
    return (eventLoop, server, client)
}

final class TestRSocket: RSocketReactiveSwift.RSocket {
    var metadataPushCallback: (Data) -> () = { _ in }
    var fireAndForgetCallback: (Payload) -> () = { _ in }
    var requestResponseCallback: (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never }
    var requestStreamCallback: (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never }
    var requestChannelCallback: (Payload, SignalProducer<Payload, Swift.Error>?) -> SignalProducer<Payload, Swift.Error> = { _, _ in .never }
    
    internal init(
        metadataPush: @escaping (Data) -> () = { _ in },
        fireAndForget: @escaping (Payload) -> () = { _ in },
        requestResponse: @escaping (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never },
        requestStream: @escaping (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never },
        requestChannel: @escaping (Payload, SignalProducer<Payload, Swift.Error>?) -> SignalProducer<Payload, Swift.Error> = { _, _ in .never }
    ) {
        self.metadataPushCallback = metadataPush
        self.fireAndForgetCallback = fireAndForget
        self.requestResponseCallback = requestResponse
        self.requestStreamCallback = requestStream
        self.requestChannelCallback = requestChannel
    }
    
    func metadataPush(metadata: Data) { metadataPushCallback(metadata) }
    func fireAndForget(payload: Payload) { fireAndForgetCallback(payload) }
    func requestResponse(payload: Payload) -> SignalProducer<Payload, Swift.Error> { requestResponseCallback(payload) }
    func requestStream(payload: Payload) -> SignalProducer<Payload, Swift.Error> { requestStreamCallback(payload) }
    func requestChannel(payload: Payload, payloadProducer: SignalProducer<Payload, Swift.Error>?) -> SignalProducer<Payload, Swift.Error> { requestChannelCallback(payload, payloadProducer) }
}

final class RSocketReactiveSwiftTests: XCTestCase {
    func testMetadataPush() {
        let metadata = Data(String("Hello World").utf8)
        let didReceiveRequest = expectation(description: "did receive request")
        let serverResponder = TestRSocket(metadataPush: { data in
            didReceiveRequest.fulfill()
            XCTAssertEqual(data, metadata)
        })
        let (_, _, client) = setup(server: serverResponder)
        client.requester.rSocket.metadataPush(metadata: metadata)
        self.wait(for: [didReceiveRequest], timeout: 0.1)
    }
    func testFireAndForget() {
        let didReceiveRequest = expectation(description: "did receive request")
        let serverResponder = TestRSocket(fireAndForget: { payload in
            didReceiveRequest.fulfill()
            XCTAssertEqual(payload, "Hello World")
        })
        let (_, _, client) = setup(server: serverResponder)
        client.requester.rSocket.fireAndForget(payload: "Hello World")
        self.wait(for: [didReceiveRequest], timeout: 0.1)
    }
    func testRequestResponse() {
        let didReceiveRequest = expectation(description: "did receive request")
        let didReceiveResponse = expectation(description: "did receive response")
        
        let serverResponder = TestRSocket(requestResponse: { payload -> SignalProducer<Payload, Swift.Error> in
            didReceiveRequest.fulfill()
            XCTAssertEqual(payload, "Hello World")
            return SignalProducer { observer, lifetime in
                observer.send(value: "Hello World!")
                observer.sendCompleted()
            }
        })
        let (_, _, client) = setup(server: serverResponder)
        let disposable = client.requester.rSocket.requestResponse(payload: "Hello World").startWithSignal { signal, _ in
            signal.flatMapError({ error in
                XCTFail("\(error)")
                return .empty
            }).collect().observeValues { values in
                didReceiveResponse.fulfill()
                XCTAssertEqual(values, ["Hello World!"])
            }
        }
        self.wait(for: [didReceiveRequest, didReceiveResponse], timeout: 0.1)
        disposable?.dispose()
    }
    func testRequestStream() {
        let didReceiveRequest = expectation(description: "did receive request")
        let didReceiveResponse = expectation(description: "did receive response")
        let serverResponder = TestRSocket(requestStream: { payload in
            didReceiveRequest.fulfill()
            XCTAssertEqual(payload, "Hello World")
            return SignalProducer { observer, lifetime in
                observer.send(value: "Hello")
                observer.send(value: " ")
                observer.send(value: "W")
                observer.send(value: "o")
                observer.send(value: "r")
                observer.send(value: "l")
                observer.send(value: "d")
                observer.send(value: "!")
                observer.sendCompleted()
            }
        })
        let (_, _, client) = setup(server: serverResponder)
        let disposable = client.requester.rSocket.requestStream(payload: "Hello World").startWithSignal { signal, _ in
            signal.flatMapError({ error in
                XCTFail("\(error)")
                return .empty
            }).collect().observeValues { values in
                didReceiveResponse.fulfill()
                XCTAssertEqual(values, ["Hello", " ", "W", "o", "r", "l", "d", "!"])
            }
        }
        self.wait(for: [didReceiveRequest, didReceiveResponse], timeout: 0.1)
        disposable?.dispose()
    }
    func testRequestChannel() {
        let didReceiveRequestChannel = expectation(description: "did receive request channel")
        let requesterDidSendChannelMessages = expectation(description: "requester did send channel messages")
        let responderDidSendChannelMessages = expectation(description: "responder did send channel messages")
        let responderDidReceiveChannelMessages = expectation(description: "responder did receive channel messages")
        let responderDidStartListeningChannelMessages = expectation(description: "responder did start listening to channel messages")
        let requesterDidReceiveChannelMessages = expectation(description: "requester did receive channel messages")
        let serverResponder = TestRSocket(requestChannel: { payload, producer in
            didReceiveRequestChannel.fulfill()
            XCTAssertEqual(payload, "Hello Responder")
            
            producer?.startWithSignal { signal, disposable in
                responderDidStartListeningChannelMessages.fulfill()
                signal.flatMapError({ error in
                    XCTFail("\(error)")
                    return .empty
                }).map({ payload -> Payload in
                    print(payload)
                    return payload
                }).collect().observeValues { values in
                    responderDidReceiveChannelMessages.fulfill()
                    XCTAssertEqual(values, ["Hello", "from", "Requester", "on", "Channel"])
                    
                }
            }

            return SignalProducer { observer, lifetime in
                responderDidSendChannelMessages.fulfill()
                observer.send(value: "Hello")
                observer.send(value: "from")
                observer.send(value: "Responder")
                observer.send(value: "on")
                observer.send(value: "Channel")
                observer.sendCompleted()
            }
        })
        let (_, _, client) = setup(server: serverResponder)
        let requestSocket = client.requester.rSocket
        let disposable = requestSocket.requestChannel(payload: "Hello Responder", payloadProducer: .init({ observer, _ in
            requesterDidSendChannelMessages.fulfill()
            observer.send(value: "Hello")
            observer.send(value: "from")
            observer.send(value: "Requester")
            observer.send(value: "on")
            observer.send(value: "Channel")
            observer.sendCompleted()
        })).startWithSignal { signal, _ in
            signal.flatMapError({ error in
                XCTFail("\(error)")
                return .empty
            }).collect().observeValues { values in
                requesterDidReceiveChannelMessages.fulfill()
                XCTAssertEqual(values, ["Hello", "from", "Responder", "on", "Channel"])
            }
        }
        self.wait(for: [
            didReceiveRequestChannel,
            requesterDidSendChannelMessages,
            responderDidSendChannelMessages,
            responderDidStartListeningChannelMessages,
            responderDidReceiveChannelMessages,
            requesterDidReceiveChannelMessages,
        ], timeout: 0.1)
        disposable?.dispose()
    }
    // MARK: - Cancellation
    func testRequestResponseCancellation() {
        let didStartRequestSignal = expectation(description: "did start request signal")
        let didReceiveRequest = expectation(description: "did receive request")
        let didEndLifetimeOnResponder = expectation(description: "did end lifetime on responder")
        
        let serverResponder = TestRSocket(requestResponse: { payload -> SignalProducer<Payload, Swift.Error> in
            didReceiveRequest.fulfill()
            XCTAssertEqual(payload, "Hello World")
            return SignalProducer { observer, lifetime in
                lifetime.observeEnded {
                    _ = observer /// we need a strong reference to `observer`, otherwise the signal will be interrupted immediately
                    didEndLifetimeOnResponder.fulfill()
                }
            }
        })
        let (_, _, client) = setup(server: serverResponder)
        let disposable = client.requester.rSocket.requestResponse(payload: "Hello World").startWithSignal { signal, _ -> Disposable? in
            didStartRequestSignal.fulfill()
            return signal.flatMapError({ error -> Signal<Payload, Never> in
                XCTFail("\(error)")
                return .empty
            }).materialize().collect().observeValues { values in
                XCTFail("should not produce any event")
            }
        }
        self.wait(for: [didStartRequestSignal], timeout: 0.1)
        disposable?.dispose()
        self.wait(for: [didReceiveRequest, didEndLifetimeOnResponder], timeout: 0.1)
    }
    func testStreamCancellation() {
        let didStartRequestSignal = expectation(description: "did start request signal")
        let didReceiveRequest = expectation(description: "did receive request")
        let didEndLifetimeOnResponder = expectation(description: "did end lifetime on responder")
        
        let serverResponder = TestRSocket(requestStream: { payload -> SignalProducer<Payload, Swift.Error> in
            didReceiveRequest.fulfill()
            XCTAssertEqual(payload, "Hello World")
            return SignalProducer { observer, lifetime in
                lifetime.observeEnded {
                    _ = observer /// we need a strong reference to `observer`, otherwise the signal will be interrupted immediately
                    didEndLifetimeOnResponder.fulfill()
                }
            }
        })
        let (_, _, client) = setup(server: serverResponder)
        let disposable = client.requester.rSocket.requestStream(payload: "Hello World").startWithSignal { signal, _ -> Disposable? in
            didStartRequestSignal.fulfill()
            return signal.flatMapError({ error -> Signal<Payload, Never> in
                XCTFail("\(error)")
                return .empty
            }).materialize().collect().observeValues { values in
                XCTFail("should not produce any event")
            }
        }
        self.wait(for: [didStartRequestSignal], timeout: 0.1)
        disposable?.dispose()
        self.wait(for: [didReceiveRequest, didEndLifetimeOnResponder], timeout: 0.1)
    }
//    func testSignalLifetime() {
//        let signalProducerLifetimeEnded = expectation(description: "signal producer lifetime ended")
//        var observerStrongRef: Signal<Void, Never>.Observer?
//        let signalProducer = SignalProducer<Void, Never> { observer, lifetime in
//            observerStrongRef = observer
//            lifetime.observeEnded {
//                signalProducerLifetimeEnded.fulfill()
//            }
//        }
//        let signalInterrupted = self.expectation(description: "signal interrupted")
//        let disposable = signalProducer.startWithSignal { signal, _ in
//            signal.observeInterrupted {
//                signalInterrupted.fulfill()
//            }
//        }
//        disposable?.dispose()
//        wait(for: [signalProducerLifetimeEnded, signalInterrupted], timeout: 0.1)
//    }
    func testRequestChannelCancellation() {
        let didReceiveRequestChannel = expectation(description: "did receive request channel")
        let requesterDidSendChannelMessages = expectation(description: "requester did send channel messages")
        let responderDidSendChannelMessages = expectation(description: "responder did send channel messages")
        let responderDidStartListeningChannelMessages = expectation(description: "responder did start listening to channel messages")
        let responderProducerLifetimeEnded = expectation(description: "responder producer lifetime ended")
        
        let serverResponder = TestRSocket(requestChannel: { payload, producer in
            didReceiveRequestChannel.fulfill()
            XCTAssertEqual(payload, "Hello")

            producer?.startWithSignal { signal, disposable in
                responderDidStartListeningChannelMessages.fulfill()
                signal.flatMapError({ error -> Signal<Payload, Never> in
                    XCTFail("\(error)")
                    return .empty
                }).materialize().collect().observeValues { values in
                    XCTFail("should not produce any event")
                }
            }

            return SignalProducer { observer, lifetime in
                responderDidSendChannelMessages.fulfill()
                lifetime.observeEnded {
                    _ = observer
                    responderProducerLifetimeEnded.fulfill()
                }
            }
        })
        let (_, _, client) = setup(server: serverResponder)
        let requestSocket = client.requester.rSocket
        let requesterDidStartListeningChannelMessages = expectation(description: "responder did start listening to channel messages")
        let payloadProducerLifetimeEnded = expectation(description: "payload producer lifetime ended")
        let disposable = requestSocket.requestChannel(payload: "Hello", payloadProducer: .init({ observer, lifetime in
            requesterDidSendChannelMessages.fulfill()
            lifetime.observeEnded {
                _ = observer
                payloadProducerLifetimeEnded.fulfill()
            }
        })).startWithSignal { signal, _ -> Disposable? in
            requesterDidStartListeningChannelMessages.fulfill()
            return signal.flatMapError({ error -> Signal<Payload, Never> in
                XCTFail("\(error)")
                return .empty
            }).materialize().collect().observeValues { values in
                XCTFail("should not produce any event")
            }
        }
        self.wait(for: [
            didReceiveRequestChannel,
            requesterDidSendChannelMessages,
            responderDidStartListeningChannelMessages,
            responderDidSendChannelMessages,
            requesterDidStartListeningChannelMessages,
        ], timeout: 0.1)
        disposable?.dispose()
        self.wait(for: [
            responderProducerLifetimeEnded,
            payloadProducerLifetimeEnded,
        ], timeout: 0.1)
    }

}

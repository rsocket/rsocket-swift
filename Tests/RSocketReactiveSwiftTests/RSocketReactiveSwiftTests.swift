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
    ) -> (server: TestDemultiplexer, client: TestDemultiplexer) {
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
        return (server, client!)
    }
}

func setup(
    server: RSocketReactiveSwift.RSocket? = nil,
    client: RSocketReactiveSwift.RSocket? = nil
) -> (server: TestDemultiplexer, client: TestDemultiplexer) {
    let (server, client) = TestDemultiplexer.pipe(
        serverResponder: ResponderAdapter(responder: server),
        clientResponder: ResponderAdapter(responder: client))
    return (server, client)
}

final class TestRSocket: RSocketReactiveSwift.RSocket {
    var metadataPushCallback: (Data) -> () = { _ in }
    var fireAndForgetCallback: (Payload) -> () = { _ in }
    var requestResponseCallback: (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never }
    var requestStreamCallback: (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never }
    var requestChannelCallback: (Payload, Bool, SignalProducer<Payload, Swift.Error>) -> SignalProducer<Payload, Swift.Error> = { _, _, _ in .never }
    
    internal init(
        metadataPush: @escaping (Data) -> () = { _ in },
        fireAndForget: @escaping (Payload) -> () = { _ in },
        requestResponse: @escaping (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never },
        requestStream: @escaping (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never },
        requestChannel: @escaping (Payload, Bool, SignalProducer<Payload, Swift.Error>) -> SignalProducer<Payload, Swift.Error> = { _, _, _ in .never }
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
    func requestChannel(payload: Payload, isCompleted: Bool, payloadProducer: SignalProducer<Payload, Swift.Error>) -> SignalProducer<Payload, Swift.Error> { requestChannelCallback(payload, isCompleted, payloadProducer) }
}

final class RSocketReactiveSwiftTests: XCTestCase {
    
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
        let (_, client) = setup(server: serverResponder)
        client.requester.reactive.requestResponse(payload: "Hello World").startWithSignal { signal, _ in
            signal.flatMapError({ error in
                XCTFail("\(error)")
                return .empty
            }).collect().observeValues { values in
                didReceiveResponse.fulfill()
                XCTAssertEqual(values, ["Hello World!"])
            }
        }
        self.wait(for: [didReceiveRequest, didReceiveResponse], timeout: 0.1)
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
        let (_, client) = setup(server: serverResponder)
        client.requester.reactive.requestStream(payload: "Hello World").startWithSignal { signal, _ in
            signal.flatMapError({ error in
                XCTFail("\(error)")
                return .empty
            }).collect().observeValues { values in
                didReceiveResponse.fulfill()
                XCTAssertEqual(values, ["Hello", " ", "W", "o", "r", "l", "d", "!"])
            }
        }
        self.wait(for: [didReceiveRequest, didReceiveResponse], timeout: 0.1)
    }
    func testRequestChannel() {
        let didReceiveRequestChannel = expectation(description: "did receive request channel")
        let requesterDidSendChannelMessages = expectation(description: "requester did send channel messages")
        let responderDidSendChannelMessages = expectation(description: "responder did send channel messages")
        let responderDidReceiveChannelMessages = expectation(description: "responder did receive channel messages")
        let responderDidStartListeningChannelMessages = expectation(description: "responder did start listening to channel messages")
        let requesterDidReceiveChannelMessages = expectation(description: "requester did receive channel messages")
        let serverResponder = TestRSocket(requestChannel: { payload, isComplete, producer in
            didReceiveRequestChannel.fulfill()
            XCTAssertEqual(payload, "Hello Responder")
            
            producer.startWithSignal { signal, disposable in
                responderDidStartListeningChannelMessages.fulfill()
                signal.flatMapError({ error in
                    XCTFail("\(error)")
                    return .empty
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
        let (_, client) = setup(server: serverResponder)
        let requestSocket = client.requester.reactive
        requestSocket.requestChannel(payload: "Hello Responder", isCompleted: false, payloadProducer: .init({ observer, _ in
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
    }
}

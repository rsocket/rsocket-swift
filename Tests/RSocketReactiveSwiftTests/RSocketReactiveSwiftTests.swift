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

import XCTest
import ReactiveSwift
import RSocketCore
import RSocketTestUtilities
@testable import RSocketReactiveSwift

extension Data: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value.utf8)
    }
}

func setup(
    server: RSocketReactiveSwift.ResponderRSocket? = nil,
    client: RSocketReactiveSwift.ResponderRSocket? = nil
) -> (server: ReactiveSwiftClient, client: ReactiveSwiftClient) {
    let (server, client) = TestDemultiplexer.pipe(
        serverResponder: server.map { ResponderAdapter(responder:$0, encoding: .default) },
        clientResponder: client.map { ResponderAdapter(responder:$0, encoding: .default) }
    )
    return (
        ReactiveSwiftClient(CoreClient(requester: server.requester)),
        ReactiveSwiftClient(CoreClient(requester: client.requester))
    )
}

final class RSocketReactiveSwiftTests: XCTestCase {
    func testMetadataPush() throws {
        let metadata: Data = "Hello World"
        let didReceiveRequest = expectation(description: "did receive request")
        let serverResponder = TestRSocket(metadataPush: { data in
            didReceiveRequest.fulfill()
            XCTAssertEqual(data, metadata)
        })
        let (_, client) = setup(server: serverResponder)
        try client.requester(MetadataPush(), metadata: metadata)
        self.wait(for: [didReceiveRequest], timeout: 0.1)
    }
    func testFireAndForget() throws {
        let didReceiveRequest = expectation(description: "did receive request")
        let serverResponder = TestRSocket(fireAndForget: { payload in
            didReceiveRequest.fulfill()
            XCTAssertEqual(payload, "Hello World")
        })
        let (_, client) = setup(server: serverResponder)
        try client.requester(FireAndForget(), request: "Hello World")
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
                observer.send(value: "Hello World!")
                observer.send(value: "Hello World!")
            }
        })
        let (_, client) = setup(server: serverResponder)
        let disposable = client.requester(
            RequestResponse(),
            request: "Hello World"
        ).startWithSignal { signal, _ in
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
    func testRequestResponseWithMisbehavingResponderSignalProducerWhichSendsTwoValuesInsteadOfOne() {
        let didReceiveRequest = expectation(description: "did receive request")
        let didReceiveResponse = expectation(description: "did receive response")
        
        let serverResponder = TestRSocket(requestResponse: { payload -> SignalProducer<Payload, Swift.Error> in
            didReceiveRequest.fulfill()
            XCTAssertEqual(payload, "Hello World")
            return SignalProducer { observer, lifetime in
                observer.send(value: "Hello World!")
                observer.send(value: "one value two much")
                observer.sendCompleted()
            }
        })
        let (_, client) = setup(server: serverResponder)
        let disposable = client.requester(
            RequestResponse(),
            request: "Hello World"
        ).startWithSignal { signal, _ in
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
        let (_, client) = setup(server: serverResponder)
        let disposable = client.requester(RequestStream(), request: "Hello World").startWithSignal { signal, _ in
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
        let disposable = client.requester(RequestChannel(), initialRequest: "Hello Responder", producer: .init({ observer, _ in
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
        let (_, client) = setup(server: serverResponder)
        let disposable = client.requester(RequestResponse(), request: "Hello World").startWithSignal { signal, _ -> Disposable? in
            didStartRequestSignal.fulfill()
            return signal.flatMapError({ error -> Signal<Data, Never> in
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
        let (_, client) = setup(server: serverResponder)
        let disposable = client.requester(RequestStream(), request: "Hello World").startWithSignal { signal, _ -> Disposable? in
            didStartRequestSignal.fulfill()
            return signal.flatMapError({ error -> Signal<Data, Never> in
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
    func testRequestChannelCancellation() {
        let didReceiveRequestChannel = expectation(description: "did receive request channel")
        let responderDidStartSenderProducer = expectation(description: "responder did start sender producer")
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
                responderDidStartSenderProducer.fulfill()
                lifetime.observeEnded {
                    _ = observer
                    responderProducerLifetimeEnded.fulfill()
                }
            }
        })
        let (_, client) = setup(server: serverResponder)
        let requesterDidStartListeningChannelMessages = expectation(description: "responder did start listening to channel messages")
        let payloadProducerLifetimeEnded = expectation(description: "payload producer lifetime ended")
        let requesterDidStartPayloadProducer = expectation(description: "requester did start payload producer")
        let disposable = client.requester(RequestChannel(), initialRequest: "Hello", producer: .init({ observer, lifetime in
            requesterDidStartPayloadProducer.fulfill()
            lifetime.observeEnded {
                _ = observer
                payloadProducerLifetimeEnded.fulfill()
            }
        })).startWithSignal { signal, _ -> Disposable? in
            requesterDidStartListeningChannelMessages.fulfill()
            return signal.flatMapError({ error -> Signal<Data, Never> in
                XCTFail("\(error)")
                return .empty
            }).materialize().collect().observeValues { values in
                XCTFail("should not produce any event")
            }
        }
        self.wait(for: [
            didReceiveRequestChannel,
            requesterDidStartPayloadProducer,
            responderDidStartListeningChannelMessages,
            responderDidStartSenderProducer,
            requesterDidStartListeningChannelMessages,
        ], timeout: 0.1)
        disposable?.dispose()
        self.wait(for: [
            responderProducerLifetimeEnded,
            payloadProducerLifetimeEnded,
        ], timeout: 0.1)
    }

}

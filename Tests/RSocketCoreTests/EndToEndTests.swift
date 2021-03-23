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
import NIO
import NIOExtras
import RSocketCore
import RSocketTestUtilities

final class EndToEndTests: XCTestCase {
    private static let defaultClientSetup = ClientSetupConfig(
        timeBetweenKeepaliveFrames: 500,
        maxLifetime: 5000,
        metadataEncodingMimeType: "utf8",
        dataEncodingMimeType: "utf8"
    )
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    override func tearDownWithError() throws {
        try eventLoopGroup.syncShutdownGracefully()
    }
    
    let host = "127.0.0.1"
    
    func makeServerBootstrap(
        responderSocket: RSocket = TestRSocket(),
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ServerBootstrap {
        return ServerBootstrap(group: eventLoopGroup)
            .childChannelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                ]).flatMap {
                    channel.pipeline.addRSocketServerHandlers(
                        shouldAcceptClient: shouldAcceptClient,
                        makeResponder: { _ in responderSocket }
                    )
                }
            }
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
    }
    func makeClientBootstrap(
        responderSocket: RSocket = TestRSocket(),
        config: ClientSetupConfig = EndToEndTests.defaultClientSetup,
        file: StaticString = #file,
        line: UInt = #line
    ) -> NIO.ClientBootstrap {
        return NIO.ClientBootstrap(group: eventLoopGroup)
            .channelInitializer { (channel) -> EventLoopFuture<Void> in
                channel.pipeline.addHandlers([
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
                    LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
                ]).flatMap {
                    channel.pipeline.addRSocketClientHandlers(config: config, responder: responderSocket)
                }
            }
    }
    func testClientServerSetup() throws {
        let setup = ClientSetupConfig(
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 5000,
            metadataEncodingMimeType: "utf8",
            dataEncodingMimeType: "utf8")
        
        let clientDidConnect = self.expectation(description: "client did connect to server")
        
        let server = makeServerBootstrap(shouldAcceptClient: { clientInfo in
            XCTAssertEqual(clientInfo.timeBetweenKeepaliveFrames, setup.timeBetweenKeepaliveFrames)
            XCTAssertEqual(clientInfo.maxLifetime, setup.maxLifetime)
            XCTAssertEqual(clientInfo.metadataEncodingMimeType, setup.metadataEncodingMimeType)
            XCTAssertEqual(clientInfo.dataEncodingMimeType, setup.dataEncodingMimeType)
            clientDidConnect.fulfill()
            return .accept
        })
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let channel = try makeClientBootstrap(config: setup)
            .connect(host: host, port: port)
            .wait()
        XCTAssertTrue(channel.isActive)
        self.wait(for: [clientDidConnect], timeout: 1)
    }
    func testFireAndForget() throws {
        let request = self.expectation(description: "receive request")
        let server = makeServerBootstrap(responderSocket: TestRSocket(fireAndForget: { payload in
            request.fulfill()
            XCTAssertEqual(payload, "Hello World")
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let requester = try makeClientBootstrap()
            .connect(host: host, port: port)
            .flatMap(\.pipeline.requester)
            .wait()
        
        requester.fireAndForget(payload: "Hello World")
        self.wait(for: [request], timeout: 1)
    }
    func testRequestResponseEcho() throws {
        let request = self.expectation(description: "receive request")
        let server = makeServerBootstrap(responderSocket: TestRSocket(requestResponse: { payload, output in
            request.fulfill()
            // just echo back
            output.onNext(payload, isCompletion: true)
            return TestUnidirectionalStream()
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let requester = try makeClientBootstrap()
            .connect(host: host, port: port)
            .flatMap(\.pipeline.requester)
            .wait()
        
        let response = self.expectation(description: "receive response")
        let helloWorld: Payload = "Hello World"
        let input = TestUnidirectionalStream { payload, isCompletion in
            XCTAssertEqual(payload, helloWorld)
            XCTAssertTrue(isCompletion)
            response.fulfill()
        }
        _ = requester.requestResponse(payload: helloWorld, responderStream: input)
        self.wait(for: [request, response], timeout: 1)
    }
    func testChannelEcho() throws {
        let request = self.expectation(description: "receive request")
        var echo: TestUnidirectionalStream?
        let server = makeServerBootstrap(responderSocket: TestRSocket(channel: { payload, initialRequestN, isCompletion, output in
            request.fulfill()
            XCTAssertEqual(initialRequestN, .max)
            XCTAssertFalse(isCompletion)
            echo = TestUnidirectionalStream.echo(to: output)
            // just echo back
            output.onNext(payload, isCompletion: false)
            return echo!
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let requester = try makeClientBootstrap()
            .connect(host: host, port: port)
            .flatMap(\.pipeline.requester)
            .wait()
        
        let response = self.expectation(description: "receive response")
        var input: TestUnidirectionalStream!
        weak var weakInput: TestUnidirectionalStream?
        input = TestUnidirectionalStream(onComplete: {
            response.fulfill()
            XCTAssertEqual(["Hello", " ", "W", "o", "r", "l", "d", .complete], weakInput?.events)
        })
        weakInput = input
        let output = requester.channel(payload: "Hello", initialRequestN: .max, isCompleted: false, responderStream: input!)
        output.onNext(" ", isCompletion: false)
        output.onNext("W", isCompletion: false)
        output.onNext("o", isCompletion: false)
        output.onNext("r", isCompletion: false)
        output.onNext("l", isCompletion: false)
        output.onNext("d", isCompletion: false)
        output.onComplete()
        self.wait(for: [request, response], timeout: 1)
    }
    func testStream() throws {
        let request = self.expectation(description: "receive request")
        let server = makeServerBootstrap(responderSocket: TestRSocket(stream: { payload, initialRequestN, output in
            request.fulfill()
            XCTAssertEqual(initialRequestN, .max)
            XCTAssertEqual(payload, "Hello World!")
            output.onNext("Hello", isCompletion: false)
            output.onNext(" ", isCompletion: false)
            output.onNext("W", isCompletion: false)
            output.onNext("o", isCompletion: false)
            output.onNext("r", isCompletion: false)
            output.onNext("l", isCompletion: false)
            output.onNext("d", isCompletion: true)
            return TestUnidirectionalStream()
        }))
        let port = try XCTUnwrap(try server.bind(host: host, port: 0).wait().localAddress?.port)
        
        let requester = try makeClientBootstrap()
            .connect(host: host, port: port)
            .flatMap(\.pipeline.requester)
            .wait()
        
        let response = self.expectation(description: "receive response")
        var input: TestUnidirectionalStream!
        weak var weakInput: TestUnidirectionalStream?
        input = TestUnidirectionalStream(onNext: { _, isCompletion in
            guard isCompletion else { return }
            response.fulfill()
            XCTAssertEqual(["Hello", " ", "W", "o", "r", "l", .next("d", isCompletion: true)], weakInput?.events)
        })
        weakInput = input
        _ = requester.stream(payload: "Hello World!", initialRequestN: .max, responderStream: input)
        self.wait(for: [request, response], timeout: 1)
    }
}

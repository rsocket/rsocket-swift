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

import Foundation
import NIOCore

/// Information about a client which is about to connect or is connected.
public struct SetupInfo {
    /// If the connection should honor `LEASE`
    public let honorsLease: Bool

    /// version of the client protocol implementation
    public let version: Version
    /**
     Time (in milliseconds) between `KEEPALIVE` frames that the client will send

     Value MUST be > `0`.
     - For server-to-server connections, a reasonable time interval between client `KEEPALIVE` frames is 500ms.
     - For mobile-to-server connections, the time interval between client `KEEPALIVE` frames is often > 30,000ms.
     */
    public let timeBetweenKeepaliveFrames: Int32

    /**
     Time (in milliseconds) that a client will allow a server to not respond to a `KEEPALIVE`
     before it is assumed to be dead

     Value MUST be > `0`.
     */
    public let maxLifetime: Int32

    /// Token used for client resume identification
    public let resumeIdentificationToken: Data?

    /**
     MIME Type for encoding of Metadata

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     The string MUST NOT be null terminated.
     */
    public let metadataEncodingMimeType: String

    /**
     MIME Type for encoding of Data

     This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
     Many are registered with IANA such as CBOR.
     Suffix rules MAY be used for handling layout.
     For example, `application/x.netflix+cbor` or `application/x.reactivesocket+cbor` or `application/x.netflix+json`.
     The string MUST NOT be null terminated.
     */
    public let dataEncodingMimeType: String

    /// Payload of this frame describing connection capabilities of the endpoint sending the Setup header
    public let payload: Payload
}

internal struct SetupValidator {
    internal var maximumClientVersion = Version.v1_0

    internal func validate(frame: Frame) throws -> SetupInfo {
        try validateSetup(try getSetupBody(frame))
    }

    private func getSetupBody(_ frame: Frame) throws -> SetupFrameBody {
        guard frame.streamId == .connection else {
            throw Error.invalidSetup(message: "connection needs to be setup on stream 0")
        }
        guard frame.body.type != .resume else {
            throw Error.rejectedResume(message: "resume is not supported")
        }
        guard case let .setup(setup) = frame.body else {
            throw Error.invalidSetup(message: "connection must be setup before anything else")
        }
        return setup
    }

    private func validateSetup(_ setup: SetupFrameBody) throws -> SetupInfo {
        guard setup.version <= maximumClientVersion else {
            throw Error.unsupportedSetup(message: "only version \(maximumClientVersion) and lower are supported")
        }
        guard setup.honorsLease == false else {
            throw Error.unsupportedSetup(message: "leasing is not supported")
        }
        guard setup.timeBetweenKeepaliveFrames > 0 else {
            throw Error.unsupportedSetup(message: "time between keepalive frames must be greater than 0")
        }
        guard setup.maxLifetime > 0 else {
            throw Error.unsupportedSetup(message: "max lifetime must be greater than 0")
        }
        return SetupInfo(setup)
    }
}

extension SetupInfo {
    fileprivate init(_ setup: SetupFrameBody) {
        self.honorsLease = setup.honorsLease
        self.version = setup.version
        self.timeBetweenKeepaliveFrames = setup.timeBetweenKeepaliveFrames
        self.maxLifetime = setup.maxLifetime
        self.resumeIdentificationToken = setup.resumeIdentificationToken
        self.metadataEncodingMimeType = setup.metadataEncodingMimeType
        self.dataEncodingMimeType = setup.dataEncodingMimeType
        self.payload = setup.payload
    }
}


public enum ClientAcceptorResult {
    case accept
    case reject(reason: String)
}

/// An application can use this callback to accept or reject a given client.
/// This can be used to check if the requested MIME type and fail early if it is not supported by the Application.
public typealias ClientAcceptorCallback = (SetupInfo) -> ClientAcceptorResult

public typealias InitializeConnection = (SetupInfo, Channel) -> EventLoopFuture<Void>


/// `MessageBufferHandler` buffers all incoming messages until `self` is removed from the `ChannelPipeline`.
/// On removal, it forwards all received messages in order to the next channel handler.
fileprivate final class MessageBufferHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = NIOAny
    
    /// buffered messages that come in while `state` == `.processing`
    private var receivedMessagesDuringProcessing: [NIOAny] = []
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        receivedMessagesDuringProcessing.append(data)
    }
    func removeHandler(context: ChannelHandlerContext, removalToken: ChannelHandlerContext.RemovalToken) {
        /// We have been formally removed from the pipeline. We should send any buffered data we have.
        /// Note that we loop twice. This is because we want to guard against being reentrantly called from fireChannelReadComplete.
        /// NOTE: original source from NIOHTTP1/HTTPServerUpgradeHandler.swift  (apple/swift-nio)
        while self.receivedMessagesDuringProcessing.count > 0 {
            while self.receivedMessagesDuringProcessing.count > 0 {
                let bufferedPart = self.receivedMessagesDuringProcessing.removeFirst()
                context.fireChannelRead(bufferedPart)
            }

            context.fireChannelReadComplete()
        }

        context.leavePipeline(removalToken: removalToken)
    }
}

/// `ConnectionEstablishmentHandler` does the connection handshake with a client.
/// It waits for a `SetupBodyFrame` and validates it.
/// The validated information is then given to `shouldAcceptClient`, so the user can accept each client individually.
/// Finally, `initializeConnection` is called to setup the pipeline after successful connection establishment.
/// `ConnectionEstablishmentHandler` will remove itself after it the returned promise of `initializeConnection` is fulfilled.
internal final class ConnectionEstablishmentHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = Frame
    typealias OutboundOut = Frame
    
    private enum State {
        /// waiting for initial setup frame from client
        case idle
        /// Did receive a frame and the frame is now being processed.
        /// No new frame should be received during this state.
        case processing
    }
    
    private let customAcceptor: ClientAcceptorCallback?
    private let initializeConnection: InitializeConnection
    
    private var state: State = .idle
    
    private let setupValidator = SetupValidator()
    
    /// Configure `ConnectionEstablishmentHandler`.  If `shouldAcceptClient` is nil, valid clients are always accepted.
    /// - Parameters:
    ///   - initializeConnection: called after successful handshake and after `shouldAcceptClient`did accept the client.
    ///   - shouldAcceptClient: called after successful validation of setup information. Use this to accept or reject individual clients.
    init(
        initializeConnection: @escaping InitializeConnection,
        shouldAcceptClient: ClientAcceptorCallback? = nil
    ) {
        self.initializeConnection = initializeConnection
        self.customAcceptor = shouldAcceptClient
    }
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard state == .idle else {
            assertionFailure("Did receive a message during processing. This should not happen because we have added a message buffer in front of this handler which should not forward any messages")
            return
        }
        state = .processing
        
        /// adding `MessageBuffer` in front of us to buffer all messages that arrive during processing the frame
        let messageBuffer = MessageBufferHandler()
        _ = context.pipeline.addHandler(messageBuffer, position: .before(self))
        
        let frame = unwrapInboundIn(data)
        do {
            let info = try setupValidator.validate(frame: frame)
            
            if let acceptor = customAcceptor {
                switch acceptor(info) {
                case .accept: break
                case let .reject(reason):
                throw Error.rejectedSetup(message: reason)
                }
            }
            
            initializeConnection(info, context.channel)
                .hop(to: context.eventLoop) // the user might return a future from another EventLoop.
                .whenComplete { result in
                    switch result {
                    case let .failure(error):
                        // something failed in initializeConnection
                        self.writeErrorAndCloseConnection(context: context, error: error)
                    case .success:
                        context.pipeline.removeHandler(context: context).whenComplete { _ in
                            /// When we remove `messageBuffer` we'll be delivering any buffered
                            context.pipeline.removeHandler(messageBuffer, promise: nil)
                        }
                    }
                }
        } catch {
            writeErrorAndCloseConnection(context: context, error: error)
        }
    }
    
    private func writeErrorAndCloseConnection(context: ChannelHandlerContext, error: Swift.Error) {
        let error = error as? Error ?? Error.connectionError(message: "unknown error")
        let frame = ErrorFrameBody(error: error).asFrame(withStreamId: .connection)
        
        let writePromise = context.writeAndFlush(wrapOutboundOut(frame))
        writePromise.whenComplete { _ in
            context.close(promise: nil)
        }
    }
}

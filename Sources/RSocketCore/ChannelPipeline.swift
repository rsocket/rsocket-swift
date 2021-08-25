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

import NIOCore

extension ChannelPipeline {
    public func addRSocketClientHandlers(
        config: ClientConfiguration,
        setupPayload: Payload,
        responder: RSocket? = nil,
        connectedPromise: EventLoopPromise<RSocket>? = nil
    ) -> EventLoopFuture<Void> {
        addRSocketClientHandlers(
            config: config,
            setupPayload: setupPayload,
            responder: responder,
            connectedPromise: connectedPromise,
            requesterLateFrameHandler: nil,
            responderLateFrameHandler: nil
        )
    }

    internal func addRSocketClientHandlers(
        config: ClientConfiguration,
        setupPayload: Payload,
        responder: RSocket? = nil,
        connectedPromise: EventLoopPromise<RSocket>? = nil,
        requesterLateFrameHandler: ((Frame) -> Void)? = nil,
        responderLateFrameHandler: ((Frame) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        let sendFrame: (Frame) -> () = { [weak self] frame in
            self?.writeAndFlush(NIOAny(frame), promise: nil)
        }
        let promise = eventLoop.makePromise(of: Void.self)
        let requester = Requester(streamIdGenerator: .client, eventLoop: eventLoop, sendFrame: sendFrame)
        promise.futureResult.map { requester as RSocket }.cascade(to: connectedPromise)
        let (timeBetweenKeepaliveFrames, maxLifetime): (Int32, Int32)
        do {
            (timeBetweenKeepaliveFrames, maxLifetime) = try config.validateKeepalive()
        } catch {
            promise.fail(error)
            return promise.futureResult
        }
        return addHandlers([
            FrameDecoderHandler(),
            FrameEncoderHandler(maximumFrameSize: config.fragmentation.maximumOutgoingFragmentSize),
            ConnectionStateHandler(),
            SetupWriter(
                timeBetweenKeepaliveFrames: timeBetweenKeepaliveFrames,
                maxLifetime: maxLifetime,
                metadataEncodingMimeType: config.encoding.metadata.rawValue,
                dataEncodingMimeType: config.encoding.data.rawValue,
                payload: setupPayload,
                connectedPromise: promise
            ),
            DemultiplexerHandler(
                connectionSide: .client,
                requester: requester,
                responder: Responder(responderSocket: responder, eventLoop: eventLoop, sendFrame: sendFrame)
            ),
            KeepaliveHandler(
                timeBetweenKeepaliveFrames: timeBetweenKeepaliveFrames,
                maxLifetime: maxLifetime,
                connectionSide: ConnectionRole.client
            ),
        ])
    }
}

extension ChannelPipeline {
    public func addRSocketServerHandlers(
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        makeResponder: ((SetupInfo) -> RSocket?)? = nil,
        maximumFrameSize: Int? = nil
    ) -> EventLoopFuture<Void> {
        addRSocketServerHandlers(
            shouldAcceptClient: shouldAcceptClient,
            makeResponder: makeResponder,
            maximumFrameSize: maximumFrameSize,
            requesterLateFrameHandler: nil,
            responderLateFrameHandler: nil
        )
    }
    internal func addRSocketServerHandlers(
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        makeResponder: ((SetupInfo) -> RSocket?)? = nil,
        maximumFrameSize: Int? = nil,
        requesterLateFrameHandler: ((Frame) -> Void)? = nil,
        responderLateFrameHandler: ((Frame) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        let maximumFrameSize = maximumFrameSize ?? ClientConfiguration.Fragmentation.default.maximumIncomingFragmentSize
        return addHandlers([
            FrameDecoderHandler(),
            FrameEncoderHandler(maximumFrameSize: maximumFrameSize),
            ConnectionStateHandler(),
            ConnectionEstablishmentHandler(initializeConnection: { [unowned self] (info, channel) in
                let responder = makeResponder?(info)
                let sendFrame: (Frame) -> () = { [weak self] frame in
                    self?.writeAndFlush(NIOAny(frame), promise: nil)
                }
                return channel.pipeline.addHandlers([
                    DemultiplexerHandler(
                        connectionSide: .server,
                        requester: Requester(streamIdGenerator: .server, eventLoop: eventLoop, sendFrame: sendFrame),
                        responder: Responder(responderSocket: responder, eventLoop: eventLoop, sendFrame: sendFrame)
                    ),
                    KeepaliveHandler(timeBetweenKeepaliveFrames: info.timeBetweenKeepaliveFrames, maxLifetime: info.maxLifetime, connectionSide: ConnectionRole.server),
                ])
            }, shouldAcceptClient: shouldAcceptClient)
        ])
    }
}

// TODO: REMOVE
extension ChannelPipeline {
    public var requester: EventLoopFuture<RSocket> {
        self.handler(type: DemultiplexerHandler.self).map { $0.requester }
    }
}

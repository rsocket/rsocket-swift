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

import NIO

extension ChannelPipeline {
    public func addRSocketClientHandlers(
        config: ClientSetupConfig,
        responder: RSocket? = nil,
        maximumFrameSize: Int32? = nil,
        connectedPromise: EventLoopPromise<RSocket>? = nil
    ) -> EventLoopFuture<Void> {
        addRSocketClientHandlers(
            config: config,
            responder: responder,
            maximumFrameSize: maximumFrameSize,
            connectedPromise: connectedPromise,
            requesterLateFrameHandler: nil,
            responderLateFrameHandler: nil
        )
    }
    internal func addRSocketClientHandlers(
        config: ClientSetupConfig,
        responder: RSocket? = nil,
        maximumFrameSize: Int32? = nil,
        connectedPromise: EventLoopPromise<RSocket>? = nil,
        requesterLateFrameHandler: ((Frame) -> Void)? = nil,
        responderLateFrameHandler: ((Frame) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        let maximumFrameSize = maximumFrameSize ?? Payload.Constants.defaultMaximumFrameSize
        let sendFrame: (Frame) -> () = { [weak self] frame in
            self?.writeAndFlush(NIOAny(frame), promise: nil)
        }
        let promise = eventLoop.makePromise(of: Void.self)
        let requester = Requester(streamIdGenerator: .client, eventLoop: eventLoop, sendFrame: sendFrame)
        promise.futureResult.map { requester as RSocket }.cascade(to: connectedPromise)
        return addHandlers([
            FrameDecoderHandler(),
            FrameEncoderHandler(maximumFrameSize: maximumFrameSize),
            SetupWriter(config: config, connectedPromise: promise),
            DemultiplexerHandler(
                connectionSide: .client,
                requester: requester,
                responder: Responder(responderSocket: responder, eventLoop: eventLoop, sendFrame: sendFrame)
            ),
            ConnectionStreamHandler(),
        ])
    }
}

extension ChannelPipeline {
    public func addRSocketServerHandlers(
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        makeResponder: ((SetupInfo) -> RSocket?)? = nil,
        maximumFrameSize: Int32? = nil
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
        maximumFrameSize: Int32? = nil,
        requesterLateFrameHandler: ((Frame) -> Void)? = nil,
        responderLateFrameHandler: ((Frame) -> Void)? = nil
    ) -> EventLoopFuture<Void> {
        let maximumFrameSize = maximumFrameSize ?? Payload.Constants.defaultMaximumFrameSize
        return addHandlers([
            FrameDecoderHandler(),
            FrameEncoderHandler(maximumFrameSize: maximumFrameSize),
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
                    ConnectionStreamHandler(),
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

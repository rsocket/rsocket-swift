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
        responder: RSocket,
        maximumFrameSize: Int32? = nil
    ) -> EventLoopFuture<Void> {
        let maximumFrameSize = maximumFrameSize ?? Payload.Constants.minMtuSize
        let sendFrame: (Frame) -> () = { [weak self] frame in
            self?.writeAndFlush(NIOAny(frame), promise: nil)
        }
        return addHandlers([
            FrameDecoderHandler(),
            FrameEncoderHandler(maximumFrameSize: maximumFrameSize),
            SetupWriter(config: config),
            DemultiplexerHandler(
                connectionSide: .client,
                requester: Requester(streamIdGenerator: .client, eventLoop: eventLoop, sendFrame: sendFrame),
                responder: Responder(responderSocket: responder, eventLoop: eventLoop, sendFrame: sendFrame)
            ),
            ConnectionStreamHandler(),
        ])
    }
}

extension ChannelPipeline {
    public func addRSocketServerHandlers(
        shouldAcceptClient: ClientAcceptorCallback? = nil,
        makeResponder: @escaping (SetupInfo) -> RSocket,
        maximumFrameSize: Int32? = nil
    ) -> EventLoopFuture<Void> {
        let maximumFrameSize = maximumFrameSize ?? Payload.Constants.minMtuSize
        return addHandlers([
            FrameDecoderHandler(),
            FrameEncoderHandler(maximumFrameSize: maximumFrameSize),
            ConnectionEstablishmentHandler(initializeConnection: { [unowned self] (info, channel) in
                let responder = makeResponder(info)
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

extension ChannelPipeline {
    public func requesterSocket() -> EventLoopFuture<RSocket> {
        self.handler(type: DemultiplexerHandler.self).map({ $0.requester as RSocket })
    }
}

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

/// Writes a setup frame when the channel becomes active and removes itself immediately afterwards
internal final class SetupWriter: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = Frame
    typealias OutboundOut = Frame
    private let setup: ClientSetupConfig
    private let connectedPromise: EventLoopPromise<Void>?
    
    internal init(config: ClientSetupConfig, connectedPromise: EventLoopPromise<Void>? = nil) {
        self.setup = config
        self.connectedPromise = connectedPromise
    }
    func handlerAdded(context: ChannelHandlerContext) {
        if context.channel.isActive {
            onActive(context: context)
        }
    }
    func channelActive(context: ChannelHandlerContext) {
        onActive(context: context)
    }
    private func onActive(context: ChannelHandlerContext) {
        context.writeAndFlush(self.wrapOutboundOut(SetupFrameBody(
            honorsLease: false,
            version: .current,
            timeBetweenKeepaliveFrames: setup.timeBetweenKeepaliveFrames,
            maxLifetime: setup.maxLifetime,
            resumeIdentificationToken: nil,
            metadataEncodingMimeType: setup.metadataEncodingMimeType,
            dataEncodingMimeType: setup.dataEncodingMimeType,
            payload: setup.payload
        ).asFrame()), promise: nil)
        context.channel.pipeline.removeHandler(context: context).eventLoop.assertInEventLoop()
        connectedPromise?.succeed(())
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        assertionFailure("should never receive data because we remove this handler right after the channel becomes active")
        /// We need to conform to `ChannelInboundHandler` to get called when the channel becomes active and we remove ourself immediately after the channel becomes active
        /// If, for whatever reason, this method gets called, we just forward the data in release mode
        context.fireChannelRead(data)
    }
}


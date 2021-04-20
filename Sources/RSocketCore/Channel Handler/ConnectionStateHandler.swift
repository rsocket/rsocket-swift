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

internal final class ConnectionStateHandler {
    private var isConnectionClosed = false
}

extension ConnectionStateHandler: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias InboundOut = Frame

    internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch (frame.streamId, frame.body.type) {
        case (.connection, .error):
            context.close(mode: .all).whenComplete { _ in
                context.fireChannelRead(data)
            }
        default:
            context.fireChannelRead(data)
        }
    }
}

extension ConnectionStateHandler: ChannelOutboundHandler {
    typealias OutboundIn = Frame
    typealias OutboundOut = Frame

    internal func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        guard !isConnectionClosed else { return }
        let future = context.write(data)
        let frame = unwrapOutboundIn(data)
        switch (frame.streamId, frame.body.type) {
        case (.connection, .error):
            isConnectionClosed = true
            future.flatMap {
                context.close(mode: .all)
            }.cascade(to: promise)
        default:
            future.cascade(to: promise)
        }
    }
}

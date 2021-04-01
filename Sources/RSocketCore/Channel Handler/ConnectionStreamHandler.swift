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
import NIO

final class ConnectionStreamHandler {
    private var keepAliveHandle: RepeatedTask?
    private var lastReceivedTime = ProcessInfo.processInfo.systemUptime
    private var timeBetweenKeepaliveFrames: Int32
    private var maxLifetime: Int32
    private let connectionSide: ConnectionRole
    private let now: () -> TimeInterval

    init(timeBetweenKeepaliveFrames: Int32,
         maxLifetime: Int32,
         connectionSide: ConnectionRole,
         now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.timeBetweenKeepaliveFrames = timeBetweenKeepaliveFrames
        self.maxLifetime = maxLifetime
        self.connectionSide = connectionSide
        self.now = now
    }
}

extension ConnectionStreamHandler: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias OutboundOut = Frame

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch frame.body {
        case let .keepalive(body):
            lastReceivedTime = ProcessInfo.processInfo.systemUptime
            if body.respondWithKeepalive {
                let keepAliveFrame = KeepAliveFrameBody(respondWithKeepalive: false, lastReceivedPosition: 0, data: Data()).asFrame()
                context.channel.writeAndFlush(keepAliveFrame, promise: nil)
            }
        default:
            break
        }
    }

    func channelActive(context: ChannelHandlerContext) {
        guard timeBetweenKeepaliveFrames > 0 else { return }
        lastReceivedTime = ProcessInfo.processInfo.systemUptime
        switch connectionSide {
        case .client:
            keepAliveHandle = context.eventLoop.scheduleRepeatedAsyncTask(initialDelay: .milliseconds(Int64(timeBetweenKeepaliveFrames)), delay: .milliseconds(Int64(timeBetweenKeepaliveFrames))) { task in
                if Int32((self.lastReceivedTime - self.now()) * 1000) > self.maxLifetime {
                    let errorFrame = Error.connectionClose(message: "KeepAlive timeout exceeded").asFrame(withStreamId: .connection)
                    context.channel.writeAndFlush(errorFrame, promise: nil)
                    task.cancel()
                    return context.eventLoop.makeFailedFuture(Error.applicationError(message: "KeepAliveHandler Shutdown"))
                } else {
                    let keepAliveFrame = KeepAliveFrameBody(respondWithKeepalive: true, lastReceivedPosition: 0, data: Data()).asFrame()
                    context.channel.writeAndFlush(keepAliveFrame, promise: nil)
                    return context.eventLoop.makeSucceededFuture(())
                }
            }
        default:
            break
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        keepAliveHandle?.cancel()
    }
}

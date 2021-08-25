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

final class KeepaliveHandler {
    private var keepAliveHandle: RepeatedTask?
    
    /// receive time in **seconds** of the last keepalive frame
    private var lastReceivedTime: TimeInterval
    /// time is in **milliseconds**
    private let timeBetweenKeepaliveFrames: Int32
    /// time is in **milliseconds**
    private let maxLifetime: Int32
    private let connectionSide: ConnectionRole
    /// returns the current time in **seconds**
    private let now: () -> TimeInterval
    
    init(
        timeBetweenKeepaliveFrames: Int32,
        maxLifetime: Int32,
        connectionSide: ConnectionRole,
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.timeBetweenKeepaliveFrames = timeBetweenKeepaliveFrames
        self.maxLifetime = maxLifetime
        self.connectionSide = connectionSide
        self.now = now
        self.lastReceivedTime = now()
    }
}

extension KeepaliveHandler: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias OutboundOut = Frame

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch frame.body {
        case let .keepalive(body):
            lastReceivedTime = now()
            if body.respondWithKeepalive {
                let keepAliveFrame = KeepAliveFrameBody(respondWithKeepalive: false, lastReceivedPosition: 0, data: Data()).asFrame()
                context.writeAndFlush(self.wrapOutboundOut(keepAliveFrame), promise: nil)
            }
        default:
            break
        }
    }
    
    func handlerAdded(context: ChannelHandlerContext) {
        if context.channel.isActive {
            /// this handler may get added to the pipeline after the channel is already active and `channelActive` is then not called
            onActive(context: context)
        }
    }

    func channelActive(context: ChannelHandlerContext) {
        onActive(context: context)
    }
    
    func onActive(context: ChannelHandlerContext) {
        guard timeBetweenKeepaliveFrames > 0 else { return }
        lastReceivedTime = now()
        guard connectionSide == .client else { return }
        
        keepAliveHandle = context.eventLoop.scheduleRepeatedAsyncTask(
            initialDelay: .milliseconds(Int64(timeBetweenKeepaliveFrames)),
            delay: .milliseconds(Int64(timeBetweenKeepaliveFrames))
        ) { [self] task in
            let elapsedTimeSinceLastKeepaliveInSeconds =  now() - lastReceivedTime
            let elapsedTimeSinceLastKeepaliveInMilliseconds = Int32((elapsedTimeSinceLastKeepaliveInSeconds * 1000).rounded(.up))
            if elapsedTimeSinceLastKeepaliveInMilliseconds >= maxLifetime {
                let errorFrame = Error.connectionClose(message: "KeepAlive timeout exceeded").asFrame(withStreamId: .connection)
                context.writeAndFlush(self.wrapOutboundOut(errorFrame), promise: nil)
                task.cancel()
                return context.eventLoop.makeFailedFuture(Error.applicationError(message: "KeepAliveHandler Shutdown"))
            } else {
                let keepAliveFrame = KeepAliveFrameBody(
                    respondWithKeepalive: true,
                    /// we do not support resumability yet, thus do not keep track of `lastReceivedPosition` and just always send 0
                    lastReceivedPosition: 0,
                    data: Data()
                ).asFrame()
                return context.writeAndFlush(self.wrapOutboundOut(keepAliveFrame))
            }
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        keepAliveHandle?.cancel()
    }
}

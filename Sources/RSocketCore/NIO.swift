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


func tcpBootstrapClientExample() {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bootstrap = ClientBootstrap(group: group)
        .channelInitializer { (channel) -> EventLoopFuture<Void> in
            channel.pipeline.addHandlers([
                /// `LengthFieldBasedFrameDecoder` and `LengthFieldBasedFrameDecoder` are part of apple/swift-nio-extra and do not yet support a lenght field lenght of 3 bytes but they are exactly what we need to support RSocket over TCP
                // LengthFieldBasedFrameDecoder(lengthFieldLength: .three),
                // LengthFieldPrepender(lengthFieldLength: .three),
                RSocketFrameDecoder(),
                RSocketFrameEncoder(),
                RSocketMultiplexer(isConnectionInitialiser: true),
                RSocketHeaderPrepender(streamID: .connection),
                ConnectionStreamHandler(), // not yet implemented
            ])
        }
    _ = bootstrap.connect(host: "localhost", port: 1234)
}

func tcpBootstrapServerExample() {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let server = ServerBootstrap(group: group)
        .childChannelInitializer { (channel) -> EventLoopFuture<Void> in
            channel.pipeline.addHandlers([
                /// `LengthFieldBasedFrameDecoder` and `LengthFieldBasedFrameDecoder` are part of apple/swift-nio-extra and do not yet support a lenght field lenght of 3 bytes but they are exactly what we need to support RSocket over TCP
                // LengthFieldBasedFrameDecoder(lengthFieldLength: .three),
                // LengthFieldPrepender(lengthFieldLength: .three),
                RSocketFrameDecoder(),
                RSocketFrameEncoder(),
                RSocketConnectionEstablishmentHandler()
                    .multiplexerInitializer({ (channel) -> EventLoopFuture<Void> in
                        channel.pipeline.addHandlers([
                            RSocketMultiplexer(isConnectionInitialiser: false),
                            RSocketHeaderPrepender(streamID: .connection),
                            ConnectionStreamHandler(), // not yet implemented
                        ])
                    })
            ])
        }
    _ = server.bind(host: "localhost", port: 1234)
}

final class RSocketConnectionEstablishmentHandler: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias OutboundOut = Frame
    
    private var multiplexerInitializer: ((Channel) -> EventLoopFuture<Void>)?
    func multiplexerInitializer(_ initializer: @escaping (Channel) -> EventLoopFuture<Void>) -> Self {
        multiplexerInitializer = initializer
        return self
    }
    // TODO: implement conneciton establishment
}

final class ConnectionStreamHandler: ChannelInboundHandler {
    typealias InboundIn = FrameBody
    typealias OutboundOut = FrameBody
}

final class RSocketFrameDecoder: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = Frame

    private let frameDecoder = FrameDecoder()

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        do {
            let frame = try frameDecoder.decode(from: &buffer)
            context.fireChannelRead(wrapInboundOut(frame))
        } catch {
            context.fireErrorCaught(error)
        }
    }
}

final class RSocketFrameEncoder: ChannelOutboundHandler {
    public typealias OutboundIn = Frame
    public typealias OutboundOut = ByteBuffer

    private let frameEncoder = FrameEncoder()

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let frame = unwrapOutboundIn(data)
        do {
            // Todo: performance optimization, we could calculate the actual capacity of the current frame
            // but for now the buffer will grow automatically
            var buffer = context.channel.allocator.buffer(capacity: FrameHeader.lengthInBytes)
            try frameEncoder.encode(frame: frame, into: &buffer)
            context.write(wrapOutboundOut(buffer), promise: promise)
        } catch {
            if frame.header.flags.contains(.ignore) {
                return
            }
            context.fireErrorCaught(error)
        }
    }
}

final class RSocketMultiplexer: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias InboundOut = FrameBody
    private var isConnectionInitialiser: Bool

    private var streams: [StreamID: Channel] = [:]
    
    internal init(
        isConnectionInitialiser: Bool
    ) {
        self.isConnectionInitialiser = isConnectionInitialiser
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        guard frame.header.streamId != .connection else {
            context.fireChannelRead(wrapInboundOut(frame.body))
            return
        }
        
        if let stream = streams[frame.header.streamId] {
            stream.pipeline.fireChannelRead(wrapInboundOut(frame.body))
        } else {
            // TODO: initialise channel if appropriated or throw error
        }
    }
}

final class RSocketHeaderPrepender: ChannelOutboundHandler {
    typealias OutboundIn = FrameBody
    typealias OutboundOut = Frame
    private let streamID: StreamID
    
    internal init(streamID: StreamID) {
        self.streamID = streamID
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let body = unwrapOutboundIn(data)
        // TODO: make header
        let header = FrameHeader(streamId: streamID, type: .cancel, flags: [])
        context.write(wrapOutboundOut(Frame(header: header, body: body)), promise: promise)
    }
}

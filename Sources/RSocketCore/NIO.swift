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


func tcpBootstrapClientExample(
    createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput,
    config: ClientSetupConfig
) {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bootstrap = ClientBootstrap(group: group)
        .channelInitializer { (channel) -> EventLoopFuture<Void> in
            let sendFrame: (Frame) -> () = { [weak channel] frame in
                channel?.writeAndFlush(frame, promise: nil)
            }
            return channel.pipeline.addHandlers([
                /// `LengthFieldBasedFrameDecoder` and `LengthFieldBasedFrameDecoder` are part of apple/swift-nio-extra and do not yet support a lenght field lenght of 3 bytes but they are exactly what we need to support RSocket over TCP
                // LengthFieldBasedFrameDecoder(lengthFieldLength: .three),
                // LengthFieldPrepender(lengthFieldLength: .three),
                RSocketFrameDecoder(),
                RSocketFrameEncoder(),
                SetupWriter(config: config),
                DemultiplexerHandler(
                    connectionSide: .client,
                    requester: Requester(streamIdGenerator: .client, sendFrame: sendFrame),
                    responder: Responder(createStream: createStream, sendFrame: sendFrame)
                ),
                ConnectionStreamHandler(),
            ])
        }
    _ = bootstrap.connect(host: "localhost", port: 1234)
}

func tcpBootstrapServerExample(
    createStream: @escaping (StreamType, Payload, StreamOutput) -> StreamInput
) {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let server = ServerBootstrap(group: group)
        .childChannelInitializer { (channel) -> EventLoopFuture<Void> in
            channel.pipeline.addHandlers([
                /// `LengthFieldBasedFrameDecoder` and `LengthFieldBasedFrameDecoder` are part of apple/swift-nio-extra and do not yet support a lenght field lenght of 3 bytes but they are exactly what we need to support RSocket over TCP
                // LengthFieldBasedFrameDecoder(lengthFieldLength: .three),
                // LengthFieldPrepender(lengthFieldLength: .three),
                RSocketFrameDecoder(),
                RSocketFrameEncoder(),
                ConnectionEstablishmentHandler(initializeConnection: { (info, channel) in
                    let sendFrame: (Frame) -> () = { [weak channel] frame in
                        channel?.writeAndFlush(frame, promise: nil)
                    }
                    return channel.pipeline.addHandlers([
                        DemultiplexerHandler(
                            connectionSide: .server,
                            requester: Requester(streamIdGenerator: .server, sendFrame: sendFrame),
                            responder: Responder(createStream: createStream, sendFrame: sendFrame)
                        ),
                        ConnectionStreamHandler(),
                    ])
                })
            ])
        }
    _ = server.bind(host: "localhost", port: 1234)
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

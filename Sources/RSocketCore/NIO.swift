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


func tcpBootstrapExample() {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let bootstrap = ClientBootstrap(group: group)
        .channelInitializer { (channel) -> EventLoopFuture<Void> in
            channel.pipeline.addHandlers([
                /// `LengthFieldBasedFrameDecoder` and `LengthFieldBasedFrameDecoder` are part of apple/swift-nio-extra and do not yet support a lenght field lenght of 3 bytes but they are exactly what we need to support RSocket over TCP
                // LengthFieldBasedFrameDecoder(lengthFieldLength: .three),
                // LengthFieldPrepender(lengthFieldLength: .three),
                RSocketFrameDecoder(),
                RSocketFrameEncoder(),
                RSocketMultiplexer(
                    isConnectionInitialiser: true,
                    streamChannelInitializer: { channel, header  in
                        channel.pipeline.addHandlers([
                            RSocketHeaderPrepender(streamID: header.streamId),
                            // TODO: add appropiated handler for given frame type
                        ])
                    }),
                RSocketHeaderPrepender(streamID: .connection),
                // ConnectionStreamHandler(), // not yet implemented
            ])
        }
    _ = bootstrap.connect(host: "localhost", port: 1234)
}

final class RSocketFrameDecoder: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = Frame
    public typealias OutboundOut = Frame

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)
        do {
            // TODO: decode
        } catch {
            context.fireErrorCaught(error)
        }
        
        context.fireChannelRead(wrapInboundOut(Frame(header: .init(streamId: .connection, type: .cancel, flags: []), body: .cancel(.init()))))
    }
}

final class RSocketFrameEncoder: ChannelOutboundHandler {
    public typealias OutboundIn = Frame
    public typealias OutboundOut = ByteBuffer

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let frame = unwrapOutboundIn(data)
        // TODO: encode
        context.write(wrapOutboundOut(ByteBuffer()), promise: promise)
    }
}

final class RSocketMultiplexer: ChannelInboundHandler {
    typealias InboundIn = Frame
    typealias InboundOut = FrameBody
    private var isConnectionInitialiser: Bool
    private var streamChannelInitializer: (Channel, FrameHeader) throws -> EventLoopFuture<Void>

    private var streams: [StreamID: Channel] = [:]
    
    internal init(
        isConnectionInitialiser: Bool,
        streamChannelInitializer: @escaping (Channel, FrameHeader) throws -> EventLoopFuture<Void>
    ) {
        self.isConnectionInitialiser = isConnectionInitialiser
        self.streamChannelInitializer = streamChannelInitializer
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

final class RSocketStreamChannel: Channel {
    var onWrite: ((NIOAny, EventLoopPromise<Void>?) -> ())?
    
    var parent: Channel? { _parent }
    
    var allocator: ByteBufferAllocator { _parent.allocator }
    
    let closePromise: EventLoopPromise<Void>
    
    var closeFuture: EventLoopFuture<Void> { closePromise.futureResult }
    
    lazy private(set) var pipeline: ChannelPipeline = .init(channel: self)
    
    var localAddress: SocketAddress? { _parent.localAddress }
    
    var remoteAddress: SocketAddress? { _parent.remoteAddress }
    
    private var _parent: Channel
    
    func setOption<Option>(_ option: Option, value: Option.Value) -> EventLoopFuture<Void> where Option : ChannelOption {
        fatalError("not implemented")
    }
    
    func getOption<Option>(_ option: Option) -> EventLoopFuture<Option.Value> where Option : ChannelOption {
        fatalError("not implemented")
    }
    
    var isWritable: Bool { _parent.isWritable }
    
    var isActive: Bool { _parent.isActive }
    
    var _channelCore: ChannelCore { self }
    
    var eventLoop: EventLoop { _parent.eventLoop }
    
    init(parent: Channel) {
        self._parent = parent
        self.closePromise = parent.eventLoop.makePromise()
    }
}

extension RSocketStreamChannel: ChannelCore {
    func localAddress0() throws -> SocketAddress {
        fatalError("not implemented \(#function)")
    }
    
    func remoteAddress0() throws -> SocketAddress {
        fatalError("not implemented \(#function)")
    }
    
    func register0(promise: EventLoopPromise<Void>?) {
        fatalError("not implemented \(#function)")
    }

    func bind0(to: SocketAddress, promise: EventLoopPromise<Void>?) {
        fatalError("not implemented \(#function)")
    }

    func connect0(to: SocketAddress, promise: EventLoopPromise<Void>?) {
        fatalError("not implemented \(#function)")
    }
    
    func write0(_ data: NIOAny, promise: EventLoopPromise<Void>?) {
        onWrite?(data, promise)
    }
    
    func flush0() {
        _parent.flush()
    }
    
    func read0() {
        _parent.read()
    }
    
    func close0(error: Swift.Error, mode: CloseMode, promise: EventLoopPromise<Void>?) {
        // TODO: close stream
    }
    
    func triggerUserOutboundEvent0(_ event: Any, promise: EventLoopPromise<Void>?) {
        // do nothing
    }
    
    func channelRead0(_ data: NIOAny) {
        // do nothing
    }
    
    func errorCaught0(error: Swift.Error) {
        // do nothing
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

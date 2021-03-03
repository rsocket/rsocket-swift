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

final class FrameEncoderHandler: ChannelOutboundHandler {
    public typealias OutboundIn = Frame
    public typealias OutboundOut = ByteBuffer

    private let frameEncoder = FrameEncoder()

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let frame = unwrapOutboundIn(data)
        do {
            // Todo: performance optimization, we could calculate the actual capacity of the current frame
            // but for now the buffer will grow automatically
            // TODO: make MTU configurable
            for fragment in frame.fragments(mtu: 64) {
                var buffer = context.channel.allocator.buffer(capacity: FrameHeader.lengthInBytes)
                try frameEncoder.encode(frame: fragment, into: &buffer)
                context.write(wrapOutboundOut(buffer), promise: promise)
            }
            context.flush()
        } catch {
            if frame.header.flags.contains(.ignore) {
                return
            }
            context.fireErrorCaught(error)
        }
    }
}

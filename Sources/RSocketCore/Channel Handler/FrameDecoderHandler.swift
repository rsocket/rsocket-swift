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

final class FrameDecoderHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = Frame

    private let frameDecoder = FrameDecoder()

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        do {
            let frame = try frameDecoder.decode(from: &buffer)
            context.fireChannelRead(wrapInboundOut(frame))
        } catch {
            assertionFailure("decoding frame failed \(error)")
            context.fireErrorCaught(error)
        }
    }
}

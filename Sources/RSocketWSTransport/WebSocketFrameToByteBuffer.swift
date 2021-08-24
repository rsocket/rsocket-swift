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

import NIOCore
import NIOWebSocket

final class WebSocketFrameToByteBuffer: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias InboundOut = ByteBuffer
    typealias OutboundOut = WebSocketFrame
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch frame.opcode {
        case .continuation:
            assertionFailure("NIOWebSocketFrameAggregator should not let any `.continuation` frames through")
            break
        case .connectionClose:
            /// TODO: We probably want to handle it the same as if an RSocket close frame and close the connection gracefully
            break
        case .ping:
            pong(context: context, frame: frame)
        case .pong:
            /// we never send ping frames, therefore should not receive pong frames
            break
        case .text:
            /// we only support binary frames
            break
        case .binary:
            context.fireChannelRead(wrapInboundOut(frame.unmaskedData))
        default:
            /// We handle all opcodes which are defined by WebSocket.
            /// This should never be reached but `WebSocketOpcode` is a struct and not an enum and we never know for sure
            break
        }
    }
    private func pong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frame.unmaskedData)
        context.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }
}

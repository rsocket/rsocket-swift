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
import NIOHTTP1
import NIOWebSocket
import RSocketCore
import NIOExtras

/// generates 16 bytes randomly and encodes them as a base64 string as defined in RFC6455 https://tools.ietf.org/html/rfc6455#section-4.1
/// - Returns: base64 encoded string
fileprivate func randomRequestKey() -> String {
    /// we may want to use `randomBytes(count:)` once the proposal is accepted: https://forums.swift.org/t/pitch-requesting-larger-amounts-of-randomness-from-systemrandomnumbergenerator/27226
    let lower = UInt64.random(in: UInt64.min...UInt64.max)
    let upper = UInt64.random(in: UInt64.min...UInt64.max)
    let data = withUnsafeBytes(of: lower) { lowerBytes in
        withUnsafeBytes(of: upper) { upperBytes in
            Data(lowerBytes) + Data(upperBytes)
        }
    }
    return data.base64EncodedString()
}

public struct WSTransport {
    public init() { }
}

extension WSTransport: TransportChannelHandler {
    public func addChannelHandler(
        channel: Channel,
        host: String,
        port: Int,
        uri: String,
        upgradeComplete: @escaping () -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        let httpHandler = HTTPInitialRequestHandler(host: host, port: port, uri: uri)
        let websocketUpgrader = NIOWebSocketClientUpgrader(
            requestKey: randomRequestKey(),
            upgradePipelineHandler: { channel, _ in
                channel.pipeline.addHandlers([
                    WebSocketFrameToByteBuffer(),
                    WebSocketFrameFromByteBuffer(),
                ])
                .flatMap(upgradeComplete)
            }
        )
        let config: NIOHTTPClientUpgradeConfiguration = (
            upgraders: [websocketUpgrader],
            completionHandler: { _ in
                channel.pipeline.removeHandler(httpHandler, promise: nil)
            }
        )
        return channel.pipeline.addHTTPClientHandlers(withClientUpgrade: config)
            
            .flatMap { channel.pipeline.addHandler(httpHandler) }
        }
}

class WebSocketFrameToByteBuffer: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias InboundOut = ByteBuffer
    typealias OutboundOut = WebSocketFrame
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = unwrapInboundIn(data)
        switch frame.opcode {
        case .continuation:
            /// we currently do not support WebSocket fragmentation
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
            /// This should never be reached but WebSocketOpcode is a struct and not an enum and we never no for sure
            break
        }
    }
    private func pong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frame.unmaskedData)
        context.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }
}

fileprivate func randomMaskingKey() -> WebSocketMaskingKey {
    let mask = UInt32.random(in: UInt32.min...UInt32.max)
    return withUnsafeBytes(of: mask) { WebSocketMaskingKey($0)! }
}

class WebSocketFrameFromByteBuffer: ChannelOutboundHandler {
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = WebSocketFrame
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer = unwrapOutboundIn(data)
        let maskKey = randomMaskingKey()
        let frame = WebSocketFrame(fin: true, opcode: .binary, maskKey: maskKey, data: buffer)
        context.write(wrapOutboundOut(frame), promise: promise)
    }
}

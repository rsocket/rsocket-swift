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
import NIOHTTP1
import NIOWebSocket

internal final class HTTPInitialRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
    internal typealias InboundIn = HTTPClientResponsePart
    internal typealias OutboundOut = HTTPClientRequestPart

    private let host: String
    private let port: Int

    internal init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    internal func channelActive(context: ChannelHandlerContext) {
        print("Client connected to \(context.remoteAddress!)")

        // We are connected. It's time to send the message to the server to initialize the upgrade dance.
        var headers = HTTPHeaders()
        headers.add(name: "Host", value: "\(host):\(port)")
        headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
        headers.add(name: "Content-Length", value: "\(0)")

        let requestHead = HTTPRequestHead(version: .http1_1,
                                          method: .GET,
                                          uri: "/",
                                          headers: headers)

        context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)

        let body = HTTPClientRequestPart.body(.byteBuffer(ByteBuffer()))
        context.write(self.wrapOutboundOut(body), promise: nil)

        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }

    internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let clientResponse = self.unwrapInboundIn(data)

        print("Upgrade failed")

        switch clientResponse {
        case .head(let responseHead):
            print("Received status: \(responseHead.status)")
        case .body(let byteBuffer):
            let string = String(buffer: byteBuffer)
            print("Received: '\(string)' back from the server.")
        case .end:
            print("Closing channel.")
            context.close(promise: nil)
        }
    }

    internal func handlerRemoved(context: ChannelHandlerContext) {
        print("HTTP handler removed.")
    }

    internal func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure
        // we just pass nil as promise to reduce allocations.
        context.close(promise: nil)
    }
}

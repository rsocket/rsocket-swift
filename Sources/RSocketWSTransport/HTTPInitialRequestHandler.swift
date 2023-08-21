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
import NIOHTTP1
import NIOWebSocket

internal final class HTTPInitialRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
    internal typealias InboundIn = HTTPClientResponsePart
    internal typealias OutboundOut = HTTPClientRequestPart

    private let host: String
    private let port: Int
    private let uri: String
    private let additionalHTTPHeader: [String: String]
    private let completionhandler :(Result<Void, Error>) -> EventLoopFuture<Void>
    
    internal init(host: String, port: Int, uri: String, additionalHTTPHeader: [String: String],completionhandler : @escaping (Result<Void,Error>)-> EventLoopFuture<Void>){
        self.host = host
        self.port = port
        self.uri = uri
        self.additionalHTTPHeader = additionalHTTPHeader
        self.completionhandler = completionhandler
    }

    internal func channelActive(context: ChannelHandlerContext) {
        // We are connected. It's time to send the message to the server to initialize the upgrade dance.
        var headers = HTTPHeaders()
        headers.add(name: "host", value: "\(host):\(port)")
        headers.add(name: "content-type", value: "text/plain; charset=utf-8")
        headers.add(name: "content-length", value: "0")
        headers.add(contentsOf: additionalHTTPHeader.map({ $0 }))

        let requestHead = HTTPRequestHead(version: .http1_1,
                                          method: .GET,
                                          uri: uri,
                                          headers: headers)

        context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)

        let body = HTTPClientRequestPart.body(.byteBuffer(ByteBuffer()))
        context.write(self.wrapOutboundOut(body), promise: nil)

        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }

    internal func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // if we receive anything the upgrade failed
        context.close(promise: nil)
    }

    internal func errorCaught(context: ChannelHandlerContext, error: Error) {
        // As we are not really interested getting notified on success or failure
        // we just pass nil as promise to reduce allocations.
        let _ = completionhandler(.failure(error))
        context.close(promise: nil)
    }
}

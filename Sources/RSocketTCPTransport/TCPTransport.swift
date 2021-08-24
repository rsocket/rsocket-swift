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
import NIOExtras
import RSocketCore

public struct TCPTransport {
    public struct Endpoint: RSocketCore.Endpoint {
        public var host: String
        public var port: Int
        public var requiresTLS: Bool { false }
        public init(host: String, port: Int) {
            self.host = host
            self.port = port
        }
    }
    public init() { }
}

extension TCPTransport: TransportChannelHandler {
    public func addChannelHandler(
        channel: Channel,
        maximumIncomingFragmentSize: Int,
        endpoint: Endpoint,
        upgradeComplete: @escaping () -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        channel.pipeline.addHandlers([
            ByteToMessageHandler(
                LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes),
                maximumBufferSize: maximumIncomingFragmentSize
            ),
            LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
        ]).flatMap(upgradeComplete)
    }
}

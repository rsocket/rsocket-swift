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
import NIOExtras
@testable import RSocketCore

extension ChannelPipeline {
    func addRSocketDebugEventsHandlers(
        inboundName: String? = nil,
        outboundName: String? = nil
    ) -> EventLoopFuture<Void> {
        handler(type: FrameDecoderHandler.self).flatMap {
            self.addHandler(DebugInboundEventsHandler(), name: inboundName, position: .after($0))
        }.flatMap {
            self.handler(type: FrameEncoderHandler.self).flatMap {
                self.addHandler(DebugOutboundEventsHandler(), name: outboundName, position: .after($0))
            }
        }
    }
}

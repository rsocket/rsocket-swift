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

public class CoreClient: Client {
    public let requester: RSocketCore.RSocket
    // Channel reference to handle channel state
    public let channel: Channel
    public init(requester: RSocketCore.RSocket, channel: Channel) {
        self.requester = requester
        self.channel = channel
    }
    /// This method help to close channel connection.
    /// - Returns: EventLoopFuture<Void> as a closeFuture
    public func shutdown() -> EventLoopFuture<Void> {
        return channel.close()
    }
    deinit {
        // if chanel is active Need to close channel manually
        assert(!channel.isActive, "Channel is active close channel manually")
    }
}

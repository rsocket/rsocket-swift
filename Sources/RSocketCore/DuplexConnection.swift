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

/// Represents a connection with input/output that the protocol uses.
public protocol DuplexConnection: Closeable {
    ///
    /// - Returns the assigned `ByteBufAllocator`.
    ///
    var allocator: ByteBufferAllocator { get }

    ///
    /// Return the remote address that this connection is connected to. The returned `SocketAddress`
    /// varies by transport type
    ///
    var remoteAddress: SocketAddress { get }

    ///
    /// Delivers the given frame to the underlying transport connection. This method is non-blocking
    /// and can be safely executed from multiple threads. This method does not provide any flow-control
    /// mechanism.
    ///
    /// - Parameters:
    ///   - streamId: streamId to which the given frame relates
    ///   - frame: frame with the encoded content
    func sendFrame(streamId: Int32, frame: ByteBuffer)

    ///
    /// Send an error frame and after it is successfully sent, close the connection.
    ///
    /// - Parameter error: to encode in the error frame
    func sendErrorAndClose(error: Error)

    ///
    /// Returns a stream of all frame received on this connection.
    ///
    /// Completion:
    ///
    /// Returned `Publisher` MUST never emit a completion event
    ///
    /// Error:
    ///
    /// Returned `Publisher` can error with various transport errors. If the underlying
    /// physical connection is closed by the peer, then the returned stream from here MUST
    /// emit an appropriate close error.
    ///
    /// Multiple Subscriptions:
    ///
    /// Returned `Publisher` is not required to support multiple concurrent subscriptions.
    /// RSocket will never have multiple subscriptions to this source. Implementations MUST
    /// emit an appropriate error for subsequent concurrent subscriptions, if they do not
    /// support multiple concurrent subscriptions.
    ///
    /// - Returns Stream of all frames received.
    ///
    func receive() -> AnyPublisher<ByteBuffer, Swift.Error>
}

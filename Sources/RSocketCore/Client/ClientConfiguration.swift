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

public struct ClientConfiguration {
    /// recommended configuration for mobile-to-server connections (i.e. potential high jitter and high latency connections)
    public static let mobileToServer = ClientConfiguration(timeout: .mobileToServer)
    
    /// recommended configuration for server-to-server connections (i.e. low jitter and low latency connections)
    public static let serverToServer = ClientConfiguration(timeout: .serverToServer)
    
    /// timeout configuration which is used locally to detect a dead connection, but also send to the server during setup
    public struct Timeout {
        
        /// disables keepalive frame sending and timeout
        public static let disabled = Timeout(
            timeBetweenKeepaliveFrames: 0,
            maxLifetime: 1
        )
        
        /// recommended configuration for mobile-to-server connections (i.e. potential high jitter and high latency connections)
        public static let mobileToServer = Timeout(
            timeBetweenKeepaliveFrames: 30_000,
            maxLifetime: 60_000
        )
        
        /// recommended configuration for server-to-server connections (i.e. low jitter and low latency connections)
        public static let serverToServer = Timeout(
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 2_000
        )
        
        /// interval in **milliseconds** between sending keepalive frame
        public var timeBetweenKeepaliveFrames: Int
        
        /// total time interval in **milliseconds** after which we close the connection if we did not receive any keepalive frame from the server back
        public var maxLifetime: Int
        
        public init(
            timeBetweenKeepaliveFrames: Int,
            maxLifetime: Int
        ) {
            self.timeBetweenKeepaliveFrames = timeBetweenKeepaliveFrames
            self.maxLifetime = maxLifetime
        }
    }
    
    /// encoding configuration of metadata and data which is send to the server during setup
    public struct Encoding {
        
        /// default encoding uses `.octetStream` for metadata and data
        public static let `default` = Encoding()
        
        /// MIME Type for encoding of Metadata
        public var metadata: MIMEType
        
        /// MIME Type for encoding of Data
        public var data: MIMEType
        
        public init(
            metadata: MIMEType = .octetStream,
            data: MIMEType = .octetStream
        ) {
            self.metadata = metadata
            self.data = data
        }
    }
    
    /// local fragmentation configuration which are **not** send to the server
    public struct Fragmentation {
        
        /// limits incoming and outgoing frames to *2 to the power of 24* (16,777,215) bytes
        public static let `default` = Fragmentation()
        
        /// Maximum size of incoming RSocket frames in **bytes**.
        /// This limit is does not effect the maximum size of a frame after reassembly.
        /// It just limits the size of a single incoming fragment which can potential be part of a much larger frame.
        /// - note: This limits only the size of an RSocket frame. The transport protocol will add another couple of bytes overhead per frame. E.g. `TCPTransport` does prefix all frames with 3 bytes which encode the size of the frame in the byte-stream.
        public var maximumIncomingFragmentSize: Int
        
        /// Maximum size of outgoing RSocket frames in **bytes**.
        /// Larger frames are fragmented into multiple frames of up to this this size.
        /// - note: This limits only the size of an RSocket frame. The transport protocol will add another couple of bytes overhead per frame. E.g. `TCPTransport` does prefix all frames with 3 bytes which encode the size of the frame in the byte-stream.
        public var maximumOutgoingFragmentSize: Int
        
        public init(
            maximumIncomingFragmentSize: Int = 1 << 24,
            maximumOutgoingFragmentSize: Int = 1 << 24
        ) {
            self.maximumIncomingFragmentSize = maximumIncomingFragmentSize
            self.maximumOutgoingFragmentSize = maximumOutgoingFragmentSize
        }
    }
    
    
    /// timeout configuration which is used locally to detect a dead connection, but also send to the server during setup
    public var timeout: Timeout
    
    /// encoding configuration of metadata and data which is send to the server during setup
    public var encoding: Encoding
    
    /// local fragmentation configuration which are **not** send to the server
    public var fragmentation: Fragmentation
    
    public init(
        timeout: Timeout,
        encoding: Encoding = .default,
        fragmentation: Fragmentation = .default
    ) {
        self.timeout = timeout
        self.encoding = encoding
        self.fragmentation = fragmentation
    }
}

extension ClientConfiguration {
    /// Creates a copy and updates the property described by `keyPath` with the given `newValue`
    /// - Returns: updated configuration
    public func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, to newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }
}

extension ClientConfiguration {
    internal func validateKeepalive() throws -> (timeBetweenKeepaliveFrames: Int32, maxLifetime: Int32) {
        enum Error: Swift.Error {
            case timeBetweenKeepaliveFramesMustFitIntoAnInt32
            case timeBetweenKeepaliveFramesMustBeGreaterThanOrEqualToZero
            case maxLifetimeMustFitIntoAnInt32
            case maxLifetimeMustBeGreaterThanOrEqualToZero
            case maxLifetimeNeedsToBeGreaterThanTimeBetweenKeepaliveFrames
        }
        guard let timeBetweenKeepaliveFrames = Int32(exactly: timeout.timeBetweenKeepaliveFrames) else {
            throw Error.timeBetweenKeepaliveFramesMustFitIntoAnInt32
        }
        guard timeBetweenKeepaliveFrames >= 0 else {
            throw Error.timeBetweenKeepaliveFramesMustBeGreaterThanOrEqualToZero
        }
        guard let maxLifetime = Int32(exactly: timeout.maxLifetime) else {
            throw Error.maxLifetimeMustFitIntoAnInt32
        }
        guard maxLifetime >= 0 else {
            throw Error.maxLifetimeMustBeGreaterThanOrEqualToZero
        }
        guard maxLifetime > timeBetweenKeepaliveFrames else {
            /// limitation for now which may change in the future after we clarified the intended behaviour of `maxLifetime`
            throw Error.maxLifetimeNeedsToBeGreaterThanTimeBetweenKeepaliveFrames
        }
        return (
            timeBetweenKeepaliveFrames: timeBetweenKeepaliveFrames,
            maxLifetime: maxLifetime
        )
    }
}



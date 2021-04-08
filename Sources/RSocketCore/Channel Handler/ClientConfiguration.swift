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


/// This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
/// Many are registered with IANA such as CBOR.
public struct MIMEType: RawRepresentable, Hashable {
    public private(set) var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension MIMEType {
    
    /// default is currently `MIMEType.octetStream`
    public static let `default` = octetStream
    
    /// application/json
    public static let json = MIMEType(rawValue: "application/json")
    
    /// application/octet-stream
    public static let octetStream = MIMEType(rawValue: "application/octet-stream")
    
    /// message/x.rsocket.routing.v0
    public static let rsocketRoutingV0 = MIMEType(rawValue: "message/x.rsocket.routing.v0")
}

public struct ClientConfiguration {
    public static let `default` = ClientConfiguration()
    public struct Timeout {
        public static let defaultMobileToServer = Timeout(
            timeBetweenKeepaliveFrames: 30_000,
            maxLifetime: 60_000
        )
        public static let defaultServerToServer = Timeout(
            timeBetweenKeepaliveFrames: 500,
            maxLifetime: 2_000
        )
        public var timeBetweenKeepaliveFrames: Int
        public var maxLifetime: Int
    }
    public struct Encoding {
        public static let `default` = Encoding()
        public var metadata: MIMEType
        public var data: MIMEType
        public init(
            metadata: MIMEType = .octetStream,
            data: MIMEType = .octetStream
        ) {
            self.metadata = metadata
            self.data = data
        }
    }
    public struct Limits {
        public static let `default` = Limits()
        public var maximumIncomingFragmentSize: Int
        public var maximumOutgoingFragmentSize: Int
        public init(
            maximumIncomingFragmentSize: Int = 1 << 14,
            maximumOutgoingFragmentSize: Int = 1 << 14
        ) {
            self.maximumIncomingFragmentSize = maximumIncomingFragmentSize
            self.maximumOutgoingFragmentSize = maximumOutgoingFragmentSize
        }
    }
    public var timeout: Timeout
    public var encoding: Encoding
    public var limits: Limits
    public init(
        timeout: Timeout = .defaultMobileToServer,
        encoding: Encoding = .default,
        limits: Limits = .default
    ) {
        self.timeout = timeout
        self.encoding = encoding
        self.limits = limits
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



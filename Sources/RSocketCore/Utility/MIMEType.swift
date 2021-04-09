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


/// This SHOULD be a US-ASCII string that includes the Internet media type specified in RFC 2045.
/// Many are registered with IANA such as CBOR.
///
/// If you want to use a MIME Type which is not defined on `MIMEType`, it is recommended to add a static property trough an extension:
/// ```
/// extension MIMEType {
///     static let png = MIMEType(rawValue: "image/png")
/// }
/// ```
/// This allows to use `.png` (i.e. implicit member expression) in a context where the type can be inferred e.g:
/// ```
/// let config = ClientConfiguration
///     .mobileToServer
///     .set(\.encoding.data, to: .png)
/// ```
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

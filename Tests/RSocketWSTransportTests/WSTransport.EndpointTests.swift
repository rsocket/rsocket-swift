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

import XCTest
@testable import RSocketWSTransport

fileprivate typealias Endpoint = WSTransport.Endpoint

final class WSTransportEndpointTests: XCTestCase {
    func testURI() {
        let endpoint = Endpoint(url: URL(string: "ws://demo.rsocket.io/rsocket?key=value#fragment")!)
        XCTAssertEqual(endpoint.uri, "/rsocket?key=value")
    }
    func testURIWithEmptyPath() {
        let endpoint = Endpoint(url: URL(string: "ws://demo.rsocket.io")!)
        XCTAssertEqual(
            endpoint.uri,
            "/",
            "URI is not allowed to be empty according to RFC 2616 Section 5.1.2 Request-URI https://tools.ietf.org/html/rfc2616#page-36"
        )
    }
    func testDefaultPortForInsecureScheme() {
        let endpoint = Endpoint(url: URL(string: "ws://demo.rsocket.io/rsocket?key=value#fragment")!)
        XCTAssertEqual(endpoint.port, 80)
    }
    func testDefaultPortForInsecureSchemeWithCustomPort() {
        let endpoint = Endpoint(url: URL(string: "wss://demo.rsocket.io:89/rsocket?key=value#fragment")!)
        XCTAssertEqual(endpoint.port, 89)
    }
    func testDefaultPortForSecureScheme() {
        let endpoint = Endpoint(url: URL(string: "wss://demo.rsocket.io/rsocket?key=value#fragment")!)
        XCTAssertEqual(endpoint.port, 443)
    }
    func testDefaultPortForSecureSchemeWithCustomPort() {
        let endpoint = Endpoint(url: URL(string: "wss://demo.rsocket.io:99/rsocket?key=value#fragment")!)
        XCTAssertEqual(endpoint.port, 99)
    }
}

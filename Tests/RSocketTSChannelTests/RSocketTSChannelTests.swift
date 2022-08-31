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
#if canImport(Network)

import XCTest
@testable import RSocketTSChannel
import RSocketTestUtilities
import RSocketCore
import RSocketWSTransport
import NIOTransportServices

@available(OSX 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *)
class RSocketTSChannelTests: XCTestCase {
    var clientBootStrap: RSocketTSChannel.ClientBootstrap<WSTransport>?
    override func setUp() {
        clientBootStrap = ClientBootstrap(
            transport: WSTransport(),
            config: .mobileToServer
                .set(\.encoding.metadata, to: .messageXRSocketRoutingV0)
                .set(\.encoding.data, to: .applicationJson)
        )
    }
    /// test case for invalid url
    func testInvalidUrlErrorCatch() {
        let invalidUrlErrorCatch = expectation(description: "invalid url error catch")
        let headerDict: [String: String] = ["": ""]
        let uri = URL(string: "http://127.0.0.1/V1/Mock")!
        clientBootStrap?.configure {
            $0.channelOption(NIOTSChannelOptions.waitForActivity, value: false)
        }
        // creating connection with invalid url
        let bootstrap = clientBootStrap?.connect(to: WSTransport.Endpoint(url: uri, additionalHTTPHeader: headerDict),
                                                 payload: Payload(metadata: "", data: ""), responder: TestRSocket())
        // catch error on future fails
        bootstrap?.whenFailure({ _ in
            invalidUrlErrorCatch.fulfill()
        })
        self.wait(for: [invalidUrlErrorCatch], timeout: 0.1)
    }

}

#endif

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
import XCTest
import NIOEmbedded
import NIOCore
@testable import RSocketCore
import RSocketTestUtilities
class CoreClientTests: XCTestCase {
    /// Test case for closing Rsocket connection when core client will get deinitialize
    func testCoreClientDeinitCloseConnectionSuccessTest() {
        let channel = EmbeddedChannel()
       XCTAssertNoThrow(try channel.connect(to: SocketAddress.init(ipAddress: "127.0.0.1", port: 0)).wait())
        // initializing core client instance
        var  coreClient: CoreClient? = CoreClient(requester: TestRSocket(), channel: channel)
        XCTAssertNotNil(coreClient)
        // checking if connection is active
        XCTAssertTrue(channel.isActive)
        // checking if connection is active
        XCTAssertNoThrow(try coreClient?.shutdown().wait())
        // Deinitializing core client instance
        coreClient = nil
        // checking if connection is inactive
        XCTAssertFalse(channel.isActive)
    }
}


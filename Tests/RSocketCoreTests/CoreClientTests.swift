//
//  CoreClientTests.swift
//  
//
//  Created by Ayush Yadav on 12/07/22.
//

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
        XCTAssertNoThrow(try coreClient?.shutDown().wait())
        // Deinitializing core client instance
        coreClient = nil
        // checking if connection is inactive
        XCTAssertFalse(channel.isActive)
    }
}


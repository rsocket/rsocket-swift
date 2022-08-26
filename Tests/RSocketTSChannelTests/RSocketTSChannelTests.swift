//
//  RSocketTSChannelTests.swift
//
//
//  Created by Ayush Yadav on 25/08/22.
//
import XCTest
@testable import RSocketTSChannel
import RSocketTestUtilities
import RSocketCore
import RSocketWSTransport
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

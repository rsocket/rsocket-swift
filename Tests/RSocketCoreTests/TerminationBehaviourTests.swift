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
@testable import RSocketCore

final class RequestResponseTerminationBehaviourTests: XCTestCase {
    private var tb = RequestResponseTerminationBehaviour()
    // MARK: single termination events
    func testRequesterSendsComplete() {
        XCTAssertFalse(tb.requesterSend(.complete))
    }
    func testRequesterSendsCancel() {
        XCTAssertTrue(tb.requesterSend(.cancel))
    }
    func testRequesterSendsError() {
        XCTAssertFalse(tb.requesterSend(.error))
    }
    func testResponderSendsComplete() {
        XCTAssertTrue(tb.responderSend(.complete))
    }
    func testResponderSendsCancel() {
        XCTAssertTrue(tb.responderSend(.cancel))
    }
    func testResponderSendsError() {
        XCTAssertTrue(tb.responderSend(.error))
    }
}

final class StreamTerminationBehaviourTests: XCTestCase {
    private var tb = StreamTerminationBehaviour()
    // MARK: single termination events
    func testRequesterSendsComplete() {
        XCTAssertFalse(tb.requesterSend(.complete))
    }
    func testRequesterSendsCancel() {
        XCTAssertTrue(tb.requesterSend(.cancel))
    }
    func testRequesterSendsError() {
        XCTAssertFalse(tb.requesterSend(.error))
    }
    func testResponderSendsComplete() {
        XCTAssertTrue(tb.responderSend(.complete))
    }
    func testResponderSendsCancel() {
        XCTAssertTrue(tb.responderSend(.cancel))
    }
    func testResponderSendsError() {
        XCTAssertTrue(tb.responderSend(.error))
    }
}


final class ChannelTerminationBehaviourTests: XCTestCase {
    private var tb = ChannelTerminationBehaviour()
    // MARK: single termination events
    func testRequesterSendsComplete() {
        XCTAssertFalse(tb.requesterSend(.complete))
    }
    func testRequesterSendsCancel() {
        XCTAssertTrue(tb.requesterSend(.cancel))
    }
    func testRequesterSendsError() {
        XCTAssertTrue(tb.requesterSend(.error))
    }
    func testResponderSendsComplete() {
        XCTAssertFalse(tb.responderSend(.complete))
    }
    func testResponderSendsCancel() {
        XCTAssertFalse(tb.responderSend(.cancel))
    }
    func testResponderSendsError() {
        XCTAssertTrue(tb.responderSend(.error))
    }
    
    // MARK: double termination events
    func testRequesterCompletesBeforeResponderCancels() {
        XCTAssertFalse(tb.requesterSend(.complete))
        XCTAssertTrue(tb.responderSend(.cancel))
    }
    func testRequesterCompletesAfterResponderCancels() {
        XCTAssertFalse(tb.responderSend(.cancel))
        XCTAssertTrue(tb.requesterSend(.complete))
    }
    
    func testRequesterCompletesBeforeResponderCompletes() {
        XCTAssertFalse(tb.requesterSend(.complete))
        XCTAssertTrue(tb.responderSend(.complete))
    }
    
    func testRequesterCompletesAfterResponderCompletes() {
        XCTAssertFalse(tb.responderSend(.complete))
        XCTAssertTrue(tb.requesterSend(.complete))
    }
}


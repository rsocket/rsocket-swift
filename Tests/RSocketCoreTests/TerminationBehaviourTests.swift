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
        XCTAssertFalse(tb.shouldTerminateAfterRequesterSent(event: .complete))
    }
    func testRequesterSendsCancel() {
        XCTAssertTrue(tb.shouldTerminateAfterRequesterSent(event: .cancel))
    }
    func testRequesterSendsError() {
        XCTAssertFalse(tb.shouldTerminateAfterRequesterSent(event: .error))
    }
    func testResponderSendsComplete() {
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .complete))
    }
    func testResponderSendsCancel() {
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .cancel))
    }
    func testResponderSendsError() {
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .error))
    }
}

final class StreamTerminationBehaviourTests: XCTestCase {
    private var tb = StreamTerminationBehaviour()
    // MARK: single termination events
    func testRequesterSendsComplete() {
        XCTAssertFalse(tb.shouldTerminateAfterRequesterSent(event: .complete))
    }
    func testRequesterSendsCancel() {
        XCTAssertTrue(tb.shouldTerminateAfterRequesterSent(event: .cancel))
    }
    func testRequesterSendsError() {
        XCTAssertFalse(tb.shouldTerminateAfterRequesterSent(event: .error))
    }
    func testResponderSendsComplete() {
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .complete))
    }
    func testResponderSendsCancel() {
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .cancel))
    }
    func testResponderSendsError() {
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .error))
    }
}


final class ChannelTerminationBehaviourTests: XCTestCase {
    private var tb = ChannelTerminationBehaviour()
    // MARK: single termination events
    func testRequesterSendsComplete() {
        XCTAssertFalse(tb.shouldTerminateAfterRequesterSent(event: .complete))
    }
    func testRequesterSendsCancel() {
        XCTAssertTrue(tb.shouldTerminateAfterRequesterSent(event: .cancel))
    }
    func testRequesterSendsError() {
        XCTAssertTrue(tb.shouldTerminateAfterRequesterSent(event: .error))
    }
    func testResponderSendsComplete() {
        XCTAssertFalse(tb.shouldTerminateAfterResponderSent(event: .complete))
    }
    func testResponderSendsCancel() {
        XCTAssertFalse(tb.shouldTerminateAfterResponderSent(event: .cancel))
    }
    func testResponderSendsError() {
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .error))
    }
    
    // MARK: double termination events
    func testRequesterCompletesBeforeResponderCancels() {
        XCTAssertFalse(tb.shouldTerminateAfterRequesterSent(event: .complete))
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .cancel))
    }
    func testRequesterCompletesAfterResponderCancels() {
        XCTAssertFalse(tb.shouldTerminateAfterResponderSent(event: .cancel))
        XCTAssertTrue(tb.shouldTerminateAfterRequesterSent(event: .complete))
    }
    
    func testRequesterCompletesBeforeResponderCompletes() {
        XCTAssertFalse(tb.shouldTerminateAfterRequesterSent(event: .complete))
        XCTAssertTrue(tb.shouldTerminateAfterResponderSent(event: .complete))
    }
    
    func testRequesterCompletesAfterResponderCompletes() {
        XCTAssertFalse(tb.shouldTerminateAfterResponderSent(event: .complete))
        XCTAssertTrue(tb.shouldTerminateAfterRequesterSent(event: .complete))
    }
}


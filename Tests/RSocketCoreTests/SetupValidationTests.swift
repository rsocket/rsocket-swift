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

fileprivate let goodSetup = SetupFrameBody(
    honorsLease: false,
    version: .current,
    timeBetweenKeepaliveFrames: 500,
    maxLifetime: 10000,
    resumeIdentificationToken: nil,
    metadataEncodingMimeType: "utf8",
    dataEncodingMimeType: "utf8",
    payload: .empty
)

fileprivate extension FrameBodyProtocol {
    func modify(_ modify: (inout Self) -> ()) -> Self {
        var copy = self
        modify(&copy)
        return copy
    }
}

final class SetupValidationTests: XCTestCase {
    private let validator = SetupValidator(minimumClientVersion: .v0_2)
    func testToOldVersionIsRejected() {
        XCTAssertThrowsError(try validator.validate(frame: goodSetup.modify({
            $0.version = Version(major: 0, minor: 1)
        }).frame()))
    }
    func testCurrentVersionIsAccepted() {
        XCTAssertNoThrow(try validator.validate(frame: goodSetup.modify({
            $0.version = .current
        }).frame()))
    }
    func testNewerVersionIsAccepted() {
        XCTAssertNoThrow(try validator.validate(frame: goodSetup.modify({
            $0.version = Version(major: 1, minor: 1)
        }).frame()))
    }
    func testLeaseIsNotSupported() {
        XCTAssertThrowsError(try validator.validate(frame: goodSetup.modify({
            $0.honorsLease = true
        }).frame()))
    }
    func testResumeIsRejected() {
        XCTAssertThrowsError(try validator.validate(frame: ResumeFrameBody(
            version: .current,
            resumeIdentificationToken: Data([0, 1, 2, 3]),
            lastReceivedServerPosition: 5,
            firstAvailableClientPosition: 6
        ).frame())) { error in
            XCTAssertEqual((error as? RSocketCore.Error)?.kind, .rejectedResume)
        }
    }
}

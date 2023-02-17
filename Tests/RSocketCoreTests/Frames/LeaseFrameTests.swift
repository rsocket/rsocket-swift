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
import XCTest
@testable import RSocketCore

final class LeaseFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         9, 0, 0, 0,
                                         0, 100, 0, 0,
                                         0, 10, 109 ]

    /* Test Lease Frame initialisation with timeToLive, numberOfRequests and metadata.
     * Verify that the frame is initialised with expected values.
     */
    func testLeaseFrameInit() {
        let metadata = "test metadata".data(using: .utf8)!
        let leaseFrame = LeaseFrame(timeToLive: 100, numberOfRequests: 10, metadata: metadata)

        XCTAssertEqual(leaseFrame.header.type, .lease, "Expected lease frame type")
        XCTAssert(leaseFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(leaseFrame.timeToLive, 100)
        XCTAssertEqual(leaseFrame.numberOfRequests, 10)
        XCTAssertEqual(leaseFrame.metadata, metadata)
    }

    /* Test for valid Lease Frame.
     * Validate should not throw if frame is valid.
     */
    func testLeaseFramePassValidation() {
        let metadata = "test metadata".data(using: .utf8)!
        let leaseFrame = LeaseFrame(timeToLive: 100, numberOfRequests: 10, metadata: metadata)

        XCTAssertNoThrow(try leaseFrame.validate())
    }

    /* Test for invalid Lease Frame. */
    func testLeaseFrameFailValidation() {
        let metadata = "test metadata".data(using: .utf8)!
        let leaseFrame = LeaseFrame(timeToLive: 100, numberOfRequests: -1, metadata: metadata)

        XCTAssertThrowsError(try leaseFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "numberOfRequests has to be equal or bigger than 0")
        }
    }

    /* Test Lease Frame Encoder.
     * Encode a lease frame and check the bytes in returned byte buffer.
     */
    func testLeaseFrameEncoder() {
        let metadata = "m".data(using: .utf8)!
        let leaseFrame = LeaseFrame(timeToLive: 100, numberOfRequests: 10, metadata: metadata)

        guard var byteBuffer = try? LeaseFrameEncoder().encode(frame: leaseFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 15)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), LeaseFrameTests.bytes)
    }

    /* Test for Lease Frame Decoder.
     * Verify that the decoded byte buffer is lease frame.
     */
    func testLeaseFrameDecoder() {
        var byteBuffer = ByteBuffer(bytes: LeaseFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedLeaseFrame = try? LeaseFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedLeaseFrame.header.type, .lease, "Expected lease frame type")
        XCTAssert(decodedLeaseFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedLeaseFrame.numberOfRequests, 10)
        XCTAssertEqual(decodedLeaseFrame.timeToLive, 100)
        XCTAssertEqual(decodedLeaseFrame.metadata, "m".data(using: .utf8)!)
    }

    /* Test for Lease Frame Coding.
     * This test encodes lease frame and gets the byte buffer.
     * Then decodes the byte buffer using lease frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testLeaseFrameCoder() {
        let metadata = "test metadata".data(using: .utf8)!
        let leaseFrame = LeaseFrame(timeToLive: 1100, numberOfRequests: 32, metadata: metadata)

        guard var byteBuffer = try? LeaseFrameEncoder().encode(frame: leaseFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedLeaseFrame = try? LeaseFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedLeaseFrame.header.type, .lease, "Expected lease frame type")
        XCTAssert(decodedLeaseFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(decodedLeaseFrame.numberOfRequests, 32)
        XCTAssertEqual(decodedLeaseFrame.timeToLive, 1100)
        XCTAssertEqual(decodedLeaseFrame.metadata, metadata)
    }

    /* If metadata is nil in encoded frame, it should be nil after encoding and decoding. */
    func testLeaseFrameNilMetadata() {
        let leaseFrame = LeaseFrame(timeToLive: 1100, numberOfRequests: 32, metadata: nil)

        guard var byteBuffer = try? LeaseFrameEncoder().encode(frame: leaseFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedLeaseFrame = try? LeaseFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedLeaseFrame.header.type, .lease, "Expected lease frame type")
        XCTAssert(decodedLeaseFrame.header.flags.rawValue & FrameFlags.metadata.rawValue == 0, "Expected metadata flag to not be set")
        XCTAssertEqual(decodedLeaseFrame.metadata, nil)

    }
}

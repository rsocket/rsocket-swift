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

final class RequestResponseFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         16, 128, 100]

    /* Test Request Response Frame initialisation with streamId, fragmentsFollow and payload.
     * Verify that the frame is initialised with expected values.
     */
    func testRequestResponseInit() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestResponseFrame = RequestResponseFrame(streamId: 0, fragmentsFollow: true, payload: Payload(data: payloadData))

        XCTAssertEqual(requestResponseFrame.header.type, .requestResponse, "Expected request response frame type")
        XCTAssert(requestResponseFrame.header.flags.rawValue & FrameFlags.requestResponseFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssertEqual(requestResponseFrame.payload.data, payloadData)
    }

    /* Test Request Response Frame Encoder.
     * Encode a request response frame and check the bytes in encoded byte buffer.
     */
    func testRequestResponseEncoder() {
        let payloadData = "d".data(using: .utf8)!
        let requestResponseFrame = RequestResponseFrame(streamId: 0, fragmentsFollow: true, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestResponseFrameEncoder().encode(frame: requestResponseFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }
        XCTAssertEqual(byteBuffer.readableBytes, 7)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), RequestResponseFrameTests.bytes)
    }

    /* Test for Request Response Frame Decoder.
     * Verify that the decoded byte buffer is request response frame.
     */
    func testRequestResponseFrameDecoder() {
        var byteBuffer = ByteBuffer(bytes: RequestResponseFrameTests.bytes)
        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestResponseFrame = try? RequestResponseFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestResponseFrame.header.type, .requestResponse, "Expected request response frame type")
        XCTAssertEqual(decodedRequestResponseFrame.payload.data, "d".data(using: .utf8)!)
    }

    /* Test for Request Response Frame Coding.
     * This test encodes request response frame and gets the byte buffer.
     * Then decodes the byte buffer using request response frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testRequestResponseFrameCoder() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestResponseFrame = RequestResponseFrame(streamId: 0, fragmentsFollow: false, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestResponseFrameEncoder().encode(frame: requestResponseFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestResponseFrame = try? RequestResponseFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestResponseFrame.header.type, .requestResponse, "Expected request response frame type")
        XCTAssertEqual(decodedRequestResponseFrame.payload.data, payloadData)
    }

    func testRequestResponseFollowsFlagSet() {
        let payloadData = "".data(using: .utf8)!
        let requestResponseFrame = RequestResponseFrame(streamId: 0, fragmentsFollow: true, payload: Payload(data: payloadData))

        XCTAssertEqual(requestResponseFrame.header.type, .requestResponse, "Expected request response frame type")
        XCTAssert(requestResponseFrame.header.flags.rawValue & FrameFlags.requestResponseFollows.rawValue != 0, "Expected follows flag to be set")
    }

    func testRequestResponseFollowsFlagNotSet() {
        let payloadData = "".data(using: .utf8)!
        let requestResponseFrame = RequestResponseFrame(streamId: 0, fragmentsFollow: false, payload: Payload(data: payloadData))

        XCTAssertEqual(requestResponseFrame.header.type, .requestResponse, "Expected request response frame type")
        XCTAssert(requestResponseFrame.header.flags.rawValue & FrameFlags.requestResponseFollows.rawValue == 0, "Expected follows flag to not be set")
    }

    func testRequestResponseMetadata() {
        let payloadMetadata = "m".data(using: .utf8)!
        let payloadData = "d".data(using: .utf8)!
        let requestResponseFrame = RequestResponseFrame(streamId: 0, fragmentsFollow: true, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(requestResponseFrame.header.type, .requestResponse, "Expected request response frame type")
        XCTAssert(requestResponseFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
    }

    func testRequestResponseMetadataNil() {
        let payloadData = "d".data(using: .utf8)!
        let requestResponseFrame = RequestResponseFrame(streamId: 0, fragmentsFollow: true, payload: Payload(metadata: nil, data: payloadData))

        XCTAssertEqual(requestResponseFrame.header.type, .requestResponse, "Expected request response frame type")
        XCTAssert(requestResponseFrame.header.flags.rawValue & FrameFlags.metadata.rawValue == 0, "Expected metadata flag to not be set")
    }
}

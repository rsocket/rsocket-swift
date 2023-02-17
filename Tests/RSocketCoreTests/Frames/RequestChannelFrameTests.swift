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

final class RequestChannelFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         28, 192, 0, 0,
                                         0, 12, 100]

    /* Test Request Channel Frame initialisation with streamId, fragmentFollow, isCompletion,
     * initialRequestN, payload.
     * Verify that the frame is initialised with expected values.
     */
    func testRequestChannelInit() {
        let payloadMetadata = "test payload metadata".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: true, initialRequestN: 11, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(requestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelComplete.rawValue != 0, "Expected complete flag to be set")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
        XCTAssertEqual(requestChannelFrame.payload.data, payloadData)
        XCTAssertEqual(requestChannelFrame.initialRequestN, 11)
    }

    func testRequestChannelFramePassValidation() {
        let payloadMetadata = "test payload metadata".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: true, initialRequestN: 11, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertNoThrow(try requestChannelFrame.validate())
    }

    func testRequestChannelFrameFailValidation() {
        let payloadMetadata = "test payload metadata".data(using: .utf8)!
        let payloadData = "test payload data".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: true, initialRequestN: 0, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertThrowsError(try requestChannelFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "initialRequestN has to be bigger than 0")
        }
    }

    /* Test Request Channel Frame Encoder.
     * Encode a request channel frame and check the bytes in encoded byte buffer.
     */
    func testRequestChannelEncoder() {
        let payloadData = "d".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: true, initialRequestN: 12, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestChannelFrameEncoder().encode(frame: requestChannelFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 11)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), RequestChannelFrameTests.bytes)
    }

    /* Test for Request Channel Frame Decoder.
     * Verify that the decoded byte buffer is request channel frame.
     */
    func testRequestChannelFrameDecoder() {
        var byteBuffer = ByteBuffer(bytes: RequestChannelFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestChannelFrame = try? RequestChannelFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(decodedRequestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssert(decodedRequestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelComplete.rawValue != 0, "Expected complete flag to be set")
        XCTAssert(decodedRequestChannelFrame.header.flags.rawValue & FrameFlags.metadata.rawValue == 0, "Expected metadata flag to not be set")
        XCTAssertEqual(decodedRequestChannelFrame.payload.data, "d".data(using: .utf8)!)
        XCTAssertEqual(decodedRequestChannelFrame.initialRequestN, 12)
    }

    /* Test for Request Channel Frame Coding.
     * This test encodes request channel frame and gets the byte buffer.
     * Then decodes the byte buffer using request channel frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testRequestChannelFrameCoder() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: true, initialRequestN: 15, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestChannelFrameEncoder().encode(frame: requestChannelFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestChannelFrame = try? RequestChannelFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssertEqual(decodedRequestChannelFrame.payload.data, payloadData)
        XCTAssertEqual(decodedRequestChannelFrame.initialRequestN, 15)
    }

    /* Test for Request Channel Frame follow flag set.
     * Follow flag should be set if fragmentsFollow is true.
     */
    func testRequestChannelFollowsFlagSet() {
        let payloadData = "".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: false, initialRequestN: 15, payload: Payload(data: payloadData))

        XCTAssertEqual(requestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelFollows.rawValue != 0, "Expected follows flag to be set")
    }

    func testRequestChannelFollowsFlagNotSet() {
        let payloadData = "".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: false, isCompletion: false, initialRequestN: 15, payload: Payload(data: payloadData))

        XCTAssertEqual(requestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelFollows.rawValue == 0, "Expected follows flag to not be set")
    }

    /* Test for Request Channel Frame metadata flag set.
     * Metadata flag should be set if metadata is present in the payload.
     */
    func testRequestChannelMetadata() {
        let payloadMetadata = "m".data(using: .utf8)!
        let payloadData = "d".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: true, initialRequestN: 15, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(requestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
    }

    func testRequestChannelMetadataNil() {
        let payloadData = "d".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: true, isCompletion: true, initialRequestN: 15, payload: Payload(metadata: nil, data: payloadData))

        XCTAssertEqual(requestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.metadata.rawValue == 0, "Expected metadata flag to not be set")
    }

    /* Test for Request Channel Frame complete flag set.
     * Complete flag should be set if isCompletion is true.
     */
    func testRequestChannelComplete() {
        let payloadData = "d".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: false, isCompletion: true, initialRequestN: 15, payload: Payload(data: payloadData))

        XCTAssertEqual(requestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelComplete.rawValue != 0, "Expected complete flag to be set")
    }

    func testRequestChannelCompleteFalse() {
        let payloadData = "d".data(using: .utf8)!
        let requestChannelFrame = RequestChannelFrame(streamId: 0, fragmentsFollow: false, isCompletion: false, initialRequestN: 15, payload: Payload(data: payloadData))

        XCTAssertEqual(requestChannelFrame.header.type, .requestChannel, "Expected request Channel frame type")
        XCTAssert(requestChannelFrame.header.flags.rawValue & FrameFlags.requestChannelComplete.rawValue == 0, "Expected complete flag to not be set")
    }
}

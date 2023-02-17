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

final class RequestStreamFrameTests: XCTestCase {

    static private let bytes: [UInt8] =  [0, 0, 0, 0,
                                          24, 128, 0, 0,
                                          0, 12, 100]

    /* Test Request Stream Frame initialisation with streamId, fragementsFollow, initialRequestN
     * and payload.
     * Verify that the frame is initialised with expected values.
     */
    func testRequestStreamInit() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: true, initialRequestN: 11, payload: Payload(data: payloadData))

        XCTAssertEqual(requestStreamFrame.header.type, .requestStream, "Expected request Stream frame type")
        XCTAssert(requestStreamFrame.header.flags.rawValue & FrameFlags.requestStreamFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssertEqual(requestStreamFrame.payload.data, payloadData)
        XCTAssertEqual(requestStreamFrame.initialRequestN, 11)
    }

    func testRequestStreamFramePassValidation() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: true, initialRequestN: 11, payload: Payload(data: payloadData))

        XCTAssertNoThrow(try requestStreamFrame.validate())
    }

    func testRequestStreamFrameFailValidation() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: true, initialRequestN: 0, payload: Payload(data: payloadData))

        XCTAssertThrowsError(try requestStreamFrame.validate()) { error in
            guard case Error.connectionError(let value) = error else {
                return XCTFail("Unexpected error type")
            }

            XCTAssertEqual(value, "initialRequestN has to be bigger than 0")
        }
    }

    /* Test Request Stream Frame Encoder.
     * Encode a request stream frame and check the bytes in encoded byte buffer.
     */
    func testRequestStreamEncoder() {
        let payloadData = "d".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: true, initialRequestN: 12, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestStreamFrameEncoder().encode(frame: requestStreamFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }
        XCTAssertEqual(byteBuffer.readableBytes, 11)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), RequestStreamFrameTests.bytes)
    }

    /* Test for Request Stream Frame Decoder.
     * Verify that the decoded byte buffer is request stream frame.
     */
    func testRequestStreamFrameDecoder() {
        var byteBuffer = ByteBuffer(bytes: RequestStreamFrameTests.bytes)

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestStreamFrame = try? RequestStreamFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestStreamFrame.header.type, .requestStream, "Expected request Stream frame type")
        XCTAssertEqual(decodedRequestStreamFrame.payload.data, "d".data(using: .utf8)!)
        XCTAssertEqual(decodedRequestStreamFrame.initialRequestN, 12)
    }

    /* Test for Request Stream Frame Coding.
     * This test encodes request stream frame and gets the byte buffer.
     * Then decodes the byte buffer using request stream frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testRequestStreamFrameCoder() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: false, initialRequestN: 15, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestStreamFrameEncoder().encode(frame: requestStreamFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestStreamFrame = try? RequestStreamFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestStreamFrame.header.type, .requestStream, "Expected request Stream frame type")
        XCTAssertEqual(decodedRequestStreamFrame.payload.data, payloadData)
        XCTAssertEqual(decodedRequestStreamFrame.initialRequestN, 15)
    }

    func testRequestStreamFollowsFlagSet() {
        let payloadData = "".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: true, initialRequestN: 15, payload: Payload(data: payloadData))

        XCTAssertEqual(requestStreamFrame.header.type, .requestStream, "Expected request Stream frame type")
        XCTAssert(requestStreamFrame.header.flags.rawValue & FrameFlags.requestStreamFollows.rawValue != 0, "Expected follows flag to be set")
    }

    func testRequestStreamFollowsFlagNotSet() {
        let payloadData = "".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: false, initialRequestN: 15, payload: Payload(data: payloadData))

        XCTAssertEqual(requestStreamFrame.header.type, .requestStream, "Expected request Stream frame type")
        XCTAssert(requestStreamFrame.header.flags.rawValue & FrameFlags.requestStreamFollows.rawValue == 0, "Expected follows flag to not be set")
    }

    func testRequestStreamMetadata() {
        let payloadMetadata = "m".data(using: .utf8)!
        let payloadData = "d".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: true, initialRequestN: 15, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(requestStreamFrame.header.type, .requestStream, "Expected request Stream frame type")
        XCTAssert(requestStreamFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
    }

    func testRequestStreamMetadataNil() {
        let payloadData = "d".data(using: .utf8)!
        let requestStreamFrame = RequestStreamFrame(streamId: 0, fragmentsFollow: true, initialRequestN: 15, payload: Payload(metadata: nil, data: payloadData))

        XCTAssertEqual(requestStreamFrame.header.type, .requestStream, "Expected request Stream frame type")
        XCTAssert(requestStreamFrame.header.flags.rawValue & FrameFlags.metadata.rawValue == 0, "Expected metadata flag to not be set")
    }
}

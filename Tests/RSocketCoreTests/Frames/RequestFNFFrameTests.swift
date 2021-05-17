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

final class RequestFNFFrameTests: XCTestCase {

    static private let bytes: [UInt8] = [0, 0, 0, 0,
                                         20, 128, 100]

    /* Test Request Fire and Forget Frame initialisation with streamId,
     * fragementFollow and payload.
     * Verify that the frame is initialised with expected values.
     */
    func testRequestFNFInit() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestFNFFrame = RequestFireAndForgetFrame(streamId: 0, fragmentsFollow: true, payload: Payload(data: payloadData))

        XCTAssertEqual(requestFNFFrame.header.type, .requestFnf, "Expected request FNF frame type")
        XCTAssert(requestFNFFrame.header.flags.rawValue & FrameFlags.requestFireAndForgetFollows.rawValue != 0, "Expected follows flag to be set")
        XCTAssertEqual(requestFNFFrame.payload.data, payloadData)
    }

    /* Test Request Fire and Forget Frame Encoder.
     * Encode a request fire and forget frame and check the bytes in encoded byte buffer.
     */
    func testRequestFNFEncoder() {
        let payloadData = "d".data(using: .utf8)!
        let requestFNFFrame = RequestFireAndForgetFrame(streamId: 0, fragmentsFollow: true, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestFireAndForgetFrameEncoder().encode(frame: requestFNFFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        XCTAssertEqual(byteBuffer.readableBytes, 7)
        XCTAssertEqual(byteBuffer.readBytes(length: byteBuffer.readableBytes), RequestFNFFrameTests.bytes)
    }

    /* Test for Request Fire and Forget Frame Decoder.
     * Verify that the decoded byte buffer is request fire and forget frame.
     */
    func testRequestFNFFrameDecoder() {
        var byteBuffer = ByteBuffer(bytes: RequestFNFFrameTests.bytes)
        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestFNFFrame = try? RequestFireAndForgetFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestFNFFrame.header.type, .requestFnf, "Expected request FNF frame type")
        XCTAssertEqual(decodedRequestFNFFrame.payload.data, "d".data(using: .utf8)!)
    }

    /* Test for Request Fire and Forget Frame Coding.
     * This test encodes request fire and forget frame and gets the byte buffer.
     * Then decodes the byte buffer using request fire and forget frame decoder.
     * The decoded frame should be same as encoded frame.
     */
    func testRequestFNFFrameCoder() {
        let payloadData = "test payload data".data(using: .utf8)!
        let requestFNFFrame = RequestFireAndForgetFrame(streamId: 0, fragmentsFollow: false, payload: Payload(data: payloadData))

        guard var byteBuffer = try? RequestFireAndForgetFrameEncoder().encode(frame: requestFNFFrame, using: ByteBufferAllocator()) else {
            XCTFail("Expected byte buffer to be not nil")
            return
        }

        guard let decodedFrameHeader = try? FrameHeaderDecoder().decode(buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame header to be not nil")
            return
        }

        guard let decodedRequestFNFFrame = try? RequestFireAndForgetFrameDecoder().decode(header: decodedFrameHeader, buffer: &byteBuffer) else {
            XCTFail("Expected decoded frame to be not nil")
            return
        }

        XCTAssertEqual(decodedRequestFNFFrame.header.type, .requestFnf, "Expected request FNF frame type")
        XCTAssertEqual(decodedRequestFNFFrame.payload.data, payloadData)
    }

    /* Test for Request Fire and Forget Frame follow flag set.
     * Follow flag should be set if fragmentsFollow is true.
     */
    func testRequestFNFFollowsFlagSet() {
        let payloadData = "".data(using: .utf8)!
        let requestFNFFrame = RequestFireAndForgetFrame(streamId: 0, fragmentsFollow: true, payload: Payload(data: payloadData))

        XCTAssertEqual(requestFNFFrame.header.type, .requestFnf, "Expected request FNF frame type")
        XCTAssert(requestFNFFrame.header.flags.rawValue & FrameFlags.requestFireAndForgetFollows.rawValue != 0, "Expected follows flag to be set")
    }

    func testRequestFNFFollowsFlagNotSet() {
        let payloadData = "".data(using: .utf8)!
        let requestFNFFrame = RequestFireAndForgetFrame(streamId: 0, fragmentsFollow: false, payload: Payload(data: payloadData))

        XCTAssertEqual(requestFNFFrame.header.type, .requestFnf, "Expected request FNF frame type")
        XCTAssert(requestFNFFrame.header.flags.rawValue & FrameFlags.requestFireAndForgetFollows.rawValue == 0, "Expected follows flag to not be set")
    }

    /* Test for Request Fire and Forget Frame metadata flag set.
     * Metadata flag should be set if metadata is present.
     */
    func testRequestFNFMetadata() {
        let payloadMetadata = "m".data(using: .utf8)!
        let payloadData = "d".data(using: .utf8)!
        let requestFNFFrame = RequestFireAndForgetFrame(streamId: 0, fragmentsFollow: true, payload: Payload(metadata: payloadMetadata, data: payloadData))

        XCTAssertEqual(requestFNFFrame.header.type, .requestFnf, "Expected request FNF frame type")
        XCTAssert(requestFNFFrame.header.flags.rawValue & FrameFlags.metadata.rawValue != 0, "Expected metadata flag to be set")
    }

    func testRequestFNFMetadataNil() {
        let payloadData = "d".data(using: .utf8)!
        let requestFNFFrame = RequestFireAndForgetFrame(streamId: 0, fragmentsFollow: true, payload: Payload(metadata: nil, data: payloadData))

        XCTAssertEqual(requestFNFFrame.header.type, .requestFnf, "Expected request FNF frame type")
        XCTAssert(requestFNFFrame.header.flags.rawValue & FrameFlags.metadata.rawValue == 0, "Expected metadata flag to not be set")
    }
}

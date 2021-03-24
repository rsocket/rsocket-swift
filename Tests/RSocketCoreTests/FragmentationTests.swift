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
import RSocketTestUtilities
@testable import RSocketCore

extension RandomAccessCollection {
    public subscript(safe index: Index) -> Element? {
        guard self.indices.contains(index) else { return nil }
        return self[index]
    }
}

extension FragmentedFrameAssembler {
    mutating func process(frame: Frame?) -> FragmentationResult? {
        frame.map({ process(frame: $0) })
    }
}

fileprivate extension Payload {
    init(metadata: String, data: String) {
        self.init(metadata: Data(metadata.utf8), data: Data(data.utf8))
    }
    var size: Int32 { Int32((metadata?.count ?? 0) + data.count) }
}

final class FragmentationTests: XCTestCase {
    private let frameHeaderSize: Int32 = 6
    private let frameHeaderSizeWithMetadata: Int32 = 6 + 3
    
    // MARK: Payload without Metadata
    func testDoNotSplitPayloadIfItFitsExactlyIntoOneFrame() {
        let payload: Payload = """
        Payload without metadata which is not too large to fit into a single frame
        """
        XCTAssertEqual(payload.size, 74)
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: payload.size + frameHeaderSize
        )
        XCTAssertEqual(fragments.count, 1)
        
        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .complete(frame))
    }
    func testSplitPayloadIfPayloadIsOneByteTooBig() {
        let payload: Payload = """
        Payload without metadata which is too large to fit into a single frame
        """
        XCTAssertEqual(payload.size, 70)
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: payload.size - 1 + frameHeaderSize
        )
        XCTAssertEqual(fragments.count, 2)
        
        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .complete(frame))
    }
    func testSplitPayloadIntoTwoFragmentsIfItFitsExactlyIntoTwoFrames() {
        let payload: Payload = """
        Payload without metadata which is too large to fit into a single frame
        """
        XCTAssertEqual(payload.size, 70)
        XCTAssertTrue(
            payload.data.count.isMultiple(of: 2),
            "size of payload needs to be a multiple of two, otherwise it can't fit perfectly into two frames"
        )
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 35 + frameHeaderSize
        )
        XCTAssertEqual(fragments.count, 2)
        
        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .complete(frame))
    }
    func testSplitPayloadIntoThreeFragmentsIfItIsOneByteTooLarge() {
        let payload: Payload = """
        Payload without metadata which is too large to fit into a single frame!
        """
        XCTAssertEqual(payload.size, 71)
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 35 + frameHeaderSize
        )
        XCTAssertEqual(fragments.count, 3)
        
        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 2]), .complete(frame))
    }
    
    // MARK: Payload with Metadata
    func testDoNotSplitPayloadWithMetadataIfItFitsExactlyIntoOneFrame() {
        let payload = Payload(
            metadata: "Some Metadata",
            data: "Payload with metadata which is not too large to fit into a single frame"
        )
        XCTAssertEqual(payload.size, 84)
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: payload.size + frameHeaderSizeWithMetadata
        )
        XCTAssertEqual(fragments.count, 1)

        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .complete(frame))
    }
    func testSplitPayloadWithMetadataIfPayloadIsOneByteTooBig() {
        let payload = Payload(
            metadata: "Some Metadata",
            data: "Payload with metadata which is too large to fit into a single frame"
        )
        XCTAssertEqual(payload.size, 80)
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: payload.size - 1 + frameHeaderSizeWithMetadata
        )
        XCTAssertEqual(fragments.count, 2)

        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .complete(frame))
    }
    func testSplitPayloadWithMetadataIntoTwoFragmentsIfItFitsExactlyIntoTwoFrames() {
        let payload = Payload(
            metadata: "Some Metadata",
            data: "Payload with metadata which is too large to fit into a single frame 3b"
        )
        XCTAssertEqual(
            payload.size, 80 + 3,
            """
            First fragment should include payload and metadata but second only payload.
            Because the first fragments header needs to include the length of the metadata,
            it is 3 bytes larger than the second fragment.
            Because of this difference, we add 3 bytes to the end of the payload to fills the last fragment completely
            """
        )
        
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 40 + frameHeaderSizeWithMetadata
        )
        XCTAssertEqual(fragments.count, 2)

        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .complete(frame))
    }
    func testSplitPayloadWithMetadataIntoThreeFragmentsIfItIsOneByteTooLarge() {
        let payload = Payload(
            metadata: "Some Metadata",
            data: "Payload with metadata which is too large to fit into a single frame 3b1"
        )
        XCTAssertEqual(
            payload.size, 80 + 3 + 1,
            """
            First fragment should include payload and metadata but second only payload.
            Because the first fragments header needs to include the length of the metadata,
            it is 3 bytes larger than the second fragment.
            Because of this difference, we add 3 bytes to the end of the payload to fills the last fragment completely.
            To overflow the second fragment, we add an additional byte.
            """
        )
        
        let frame = PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 7)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 40 + frameHeaderSizeWithMetadata
        )
        XCTAssertEqual(fragments.count, 3)

        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 2]), .complete(frame))
    }
}

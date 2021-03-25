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

extension FragmentationResult {
    var isError: Bool {
        guard case .error = self else { return false }
        return true
    }
}

func XCTAssertTrue(
    _ expression: @autoclosure () throws -> Bool?,
    _ message: @autoclosure () -> String,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(try expression(), true, message(), file: file, line: line)
}
func XCTAssertTrue(
    _ expression: @autoclosure () throws -> Bool?,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(try expression(), true, file: file, line: line)
}

// - MARK: Frame Bodies with Fragmentable Payload
final class RequestResponseFragmentationTests: PayloadFragmentationTests {
    override func makeFrame(payload: Payload) -> Frame {
        RequestResponseFrameBody(payload: payload).asFrame(withStreamId: 6)
    }
}
final class FireAndForgetFragmentationTests: PayloadFragmentationTests {
    override func makeFrame(payload: Payload) -> Frame {
        RequestFireAndForgetFrameBody(payload: payload).asFrame(withStreamId: 7)
    }
}
final class StreamFragmentationTests: PayloadFragmentationTests {
    override var initialFragmentBodyHeaderSize: Int32 { 4 }
    override func makeFrame(payload: Payload) -> Frame {
        RequestStreamFrameBody(initialRequestN: 3, payload: payload).asFrame(withStreamId: 8)
    }
}
class ChannelFragmentationTests: PayloadFragmentationTests {
    override var initialFragmentBodyHeaderSize: Int32 { 4 }
    override func makeFrame(payload: Payload) -> Frame {
        RequestChannelFrameBody(isCompleted: false, initialRequestN: 4, payload: payload).asFrame(withStreamId: 9)
    }
}
final class ChannelCompletionFragmentationTests: ChannelFragmentationTests {
    override func makeFrame(payload: Payload) -> Frame {
        RequestChannelFrameBody(isCompleted: true, initialRequestN: 5, payload: payload).asFrame(withStreamId: 9)
    }
}

class PayloadFragmentationTests: XCTestCase {
    var initialFragmentBodyHeaderSize: Int32 { 0 }
    private var initialFragmentBodyHeaderSizeWithMetadata: Int32 { initialFragmentBodyHeaderSize + 3 }
    private var frameHeaderSize: Int32 { initialFragmentBodyHeaderSize + 6 }
    private var frameHeaderSizeWithMetadata: Int32 { frameHeaderSize + 3 }
    
    func makeFrame(payload: Payload) -> Frame {
        PayloadFrameBody(isCompletion: false, isNext: true, payload: payload).asFrame(withStreamId: 5)
    }
    
    // MARK: Payload without Metadata
    func testDoNotSplitPayloadIfItFitsExactlyIntoOneFrame() {
        let payload: Payload = """
        Payload without metadata which is not too large to fit into a single frame
        """
        XCTAssertEqual(payload.size, 74)
        let frame = makeFrame(payload: payload)
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
        let frame = makeFrame(payload: payload)
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
        let frame = makeFrame(payload: payload)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 35 + frameHeaderSize
        )
        XCTAssertEqual(fragments.count, 2)
        
        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .complete(frame))
    }
    func testSplitPayloadIntoThreeFragmentsIfItIsOneByteTooLarge() {
        let payload = Payload(
            data: "Payload without metadata which is too large to fit into a single frame!"
                + repeatElement(".", count: Int(initialFragmentBodyHeaderSizeWithMetadata))
        )
        
        XCTAssertEqual(payload.size, 71 + initialFragmentBodyHeaderSizeWithMetadata)
        let frame = makeFrame(payload: payload)
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
        let frame = makeFrame(payload: payload)
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
        let frame = makeFrame(payload: payload)
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
            data: "Payload with metadata which is too large to fit into a single frame" +
                repeatElement(".", count: Int(initialFragmentBodyHeaderSizeWithMetadata))
        )
        XCTAssertEqual(
            payload.size, 80 + initialFragmentBodyHeaderSizeWithMetadata,
            """
            First fragment should include payload and metadata but second only payload.
            Because the first fragments header needs to include the length of the metadata,
            it is 3 bytes larger than the second fragment.
            Because of this difference, we add 3 bytes to the end of the payload to fills the last fragment completely
            """
        )
        
        let frame = makeFrame(payload: payload)
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
            data: "Payload with metadata which is too large to fit into a single frame!" +
                repeatElement(".", count: Int(initialFragmentBodyHeaderSizeWithMetadata))
        )
        XCTAssertEqual(
            payload.size, 80 + initialFragmentBodyHeaderSizeWithMetadata + 1,
            """
            First fragment should include payload and metadata but the second fragment only data.
            Because the first fragments header needs to include the length of the metadata,
            it is 3 bytes larger than the second fragment.
            We add 3 bytes to the end of the payload to fills the last fragment completely.
            To overflow the second fragment, we add an additional byte.
            """
        )
        
        let frame = makeFrame(payload: payload)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 40 + frameHeaderSizeWithMetadata
        )
        XCTAssertEqual(fragments.count, 3)

        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 1]), .incomplete)
        XCTAssertEqual(assembler.process(frame: fragments[safe: 2]), .complete(frame))
    }
    
    // - Incomplete Fragmentation
    
    func testReceiveCancelBeforeReceivingAllFragmentsShouldResultInAnError() {
        let payload = Payload(
            metadata: "Some Metadata",
            data: "Payload with metadata which is too large to fit into a single frame"
        )
        let frame = makeFrame(payload: payload)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 40 + frameHeaderSizeWithMetadata
        )
        XCTAssertEqual(fragments.count, 2)

        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertTrue(assembler.process(frame: Error.canceled(message: "cancel").asFrame(withStreamId: .connection))?.isError)
    }
    
    func testReceiveNewRequestBeforeReceivingAllFragmentsShouldResultInAnError() {
        let payload = Payload(
            metadata: "Some Metadata",
            data: "Payload with metadata which is too large to fit into a single frame"
        )
        let frame = makeFrame(payload: payload)
        let fragments = frame.splitIntoFragmentsIfNeeded(
            maximumFrameSize: 40 + frameHeaderSizeWithMetadata
        )
        XCTAssertEqual(fragments.count, 2)

        var assembler = FragmentedFrameAssembler()
        XCTAssertEqual(assembler.process(frame: fragments[safe: 0]), .incomplete)
        XCTAssertTrue(assembler.process(frame: fragments[safe: 0])?.isError)
    }
}

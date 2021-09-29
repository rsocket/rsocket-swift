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
import NIOCore
@testable import RSocketCore

fileprivate let UInt24Max = 1 << 24 - 1

final class RootCompositeMetadataCoderTests: XCTestCase {
    func testValid() throws {
        let validCompositeMetadataList: [[CompositeMetadata]] = [
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer()),
            ],
            [
                CompositeMetadata(mimeType: .applicationJson, data: ByteBuffer(string: "{}")),
            ],
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([0])),
            ],
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([0, 1])),
            ],

            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([0])),
            ],
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([0])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([1, 2])),
            ],

            [
                CompositeMetadata(mimeType: .messageXRSocketRoutingV0, data: ByteBuffer(bytes: [6] + "stocks".utf8)),
                CompositeMetadata(mimeType: .applicationJson, data: ByteBuffer(string: #"{"isin":"US0378331005"}"#)),
            ],
            [
                CompositeMetadata(mimeType: .init(rawValue: "my-custom/mimetype"), data: ByteBuffer([0])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer([1])),
            ],

            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer(repeating: 0, count: UInt24Max)),
            ],
        ]

        for validCompositeMetadata in validCompositeMetadataList {
            let encoder = RootCompositeMetadataEncoder()
            var encodedData = try encoder.encode(validCompositeMetadata)

            let decoder = RootCompositeMetadataDecoder()
            let decodedCompositeMetadata = try decoder.decode(from: &encodedData)
            XCTAssertEqual(decodedCompositeMetadata, validCompositeMetadata)
        }
    }

    func testTooBigMetadata() {
        XCTAssertThrowsError(
            try RootCompositeMetadataEncoder()
                .encode([
                    CompositeMetadata(mimeType: .applicationOctetStream, data: ByteBuffer(repeating: 0, count: UInt24Max + 1))
                ])
        )
    }

    func testMessageToShort() throws {
        var compositeMetadata = ByteBuffer()
        try MIMETypeEncoder().encode(.applicationJson, into: &compositeMetadata)
        compositeMetadata.writeUInt24(UInt32(1))

        XCTAssertThrowsError(
            try RootCompositeMetadataDecoder()
                .decode(from: &compositeMetadata)
        )
    }
}

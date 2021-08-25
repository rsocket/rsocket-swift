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
import NIO
@testable import RSocketCore

fileprivate let UInt24Max = 1 << 24 - 1

final class RootCompositeMetadataCoderTests: XCTestCase {
    func testValid() throws {
        let validCompositeMetadataList: [[CompositeMetadata]] = [
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data()),
            ],
            [
                CompositeMetadata(mimeType: .applicationJson, data: Data("{}".utf8)),
            ],
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([0])),
            ],
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([0, 1])),
            ],

            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([0])),
            ],
            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([0])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([1, 2])),
            ],

            [
                CompositeMetadata(mimeType: .messageXRSocketRoutingV0, data: Data([6] + "stocks".utf8)),
                CompositeMetadata(mimeType: .applicationJson, data: Data(#"{"isin":"US0378331005"}"#.utf8)),
            ],
            [
                CompositeMetadata(mimeType: .init(rawValue: "my-custom/mimetype"), data: Data([0])),
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data([1])),
            ],

            [
                CompositeMetadata(mimeType: .applicationOctetStream, data: Data(repeating: 0, count: UInt24Max)),
            ],
        ]

        for validCompositeMetadata in validCompositeMetadataList {
            let encoder = RootCompositeMetadataEncoder()
            let encodedData = try encoder.encode(validCompositeMetadata)

            let decoder = RootCompositeMetadataDecoder()
            let decodedCompositeMetadata = try decoder.decode(from: encodedData)
            XCTAssertEqual(decodedCompositeMetadata, validCompositeMetadata)
        }
    }

    func testTooBigMetadata() {
        XCTAssertThrowsError(
            try RootCompositeMetadataEncoder()
                .encode([
                    CompositeMetadata(mimeType: .applicationOctetStream, data: Data(repeating: 0, count: UInt24Max + 1))
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

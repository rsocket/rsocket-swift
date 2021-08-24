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
import RSocketCore

final class MIMETypeCoderTests: XCTestCase {
    func testEncodingAndDecodingValidMIMETypes() {
        let validMIMETypes: [MIMEType] = [
            MIMEType(rawValue: ""),
            MIMEType(rawValue: "custom/mimetype"),
        ]
        
        for validMIMEType in validMIMETypes {
            XCTAssertNoThrow(try {
                let encoder = MIMETypeEncoder()
                var buffer = ByteBuffer()
                try encoder.encode(validMIMEType, into: &buffer)
                
                let decoder = MIMETypeDecoder()
                let decodedMIMEType = try decoder.decode(from: &buffer)
                
                XCTAssertEqual(validMIMEType, decodedMIMEType)
            }(), "Failed to encode/decode \(validMIMEType)")
        }
    }
    
    func testEncodingInvalidMIMEType() {
        let invalidMIMETypes: [MIMEType] = [
            MIMEType(rawValue: String(repeating: "A", count: 128)),
            MIMEType(rawValue: String(repeating: "A", count: 255)),
            MIMEType(rawValue: String(repeating: "A", count: 256)),
        ]
        
        for invalidMIMEType in invalidMIMETypes {
            let encoder = MIMETypeEncoder()
            var buffer = ByteBuffer()
            XCTAssertThrowsError(
                try encoder.encode(invalidMIMEType, into: &buffer), 
                "Did *not* fail to encode \(invalidMIMEType)"
            )
        }
    }
    
    func testEncodingAndDecodingWellKnownTypes() throws {
        let wellKnowMIMETypes = MIMEType.wellKnownMIMETypes
        for (code, mimeType) in wellKnowMIMETypes {
            let encoder = MIMETypeEncoder()
            var buffer = ByteBuffer()
            try encoder.encode(mimeType, into: &buffer)
            
            XCTAssertEqual(buffer.readableBytes, 1, "Well Known MIME types should occupy only one byte of space")
            XCTAssertEqual(buffer.getInteger(at: 0, as: UInt8.self), code.rawValue | 0b1000_0000)
            
            let decoder = MIMETypeDecoder()
            let decodedMIMEType = try decoder.decode(from: &buffer)
            
            XCTAssertEqual(mimeType, decodedMIMEType)
        }
    }
    
    func testDecodingInvalidMIMETypeWithAnEmptyString() {
        var buffer = ByteBuffer()
        buffer.writeInteger(Int8(1))
        
        let decoder = MIMETypeDecoder()
        XCTAssertThrowsError(try decoder.decode(from: &buffer))
    }
    
    func testDecodingInvalidMIMETypeWithOneCharacterTooFew() {
        var buffer = ByteBuffer()
        buffer.writeInteger(UInt8(2))
        buffer.writeString("A")
        
        let decoder = MIMETypeDecoder()
        XCTAssertThrowsError(try decoder.decode(from: &buffer))
    }
    
    func testDecodingUnknownMIMETypeCode() throws {
        let code = try XCTUnwrap(WellKnownMIMETypeCode(rawValue: 121))
    
        try XCTSkipIf(
            MIMEType.wellKnownMIMETypes.map(\.0).contains(code), 
            "we need another Well Known MIME Type Code which is actually not well known"
        )
        
        var buffer = ByteBuffer()
        buffer.writeInteger(code.rawValue | 0b1000_0000)
        
        let decoder = MIMETypeDecoder()
        XCTAssertThrowsError(try decoder.decode(from: &buffer))
    }
}

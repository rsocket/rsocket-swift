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

final class RoutingCoderTests: XCTestCase {
    func testEncodingAndDecodingValidRoutes() {
        let validRoutes: [RouteMetadata] = [
            [],
            [""],
            ["", ""],
            
            ["A"],
            ["A", "B"],
            ["A", "B", "C"],
            ["A", "B", "C", "D"],
            ["A", "B", ""],
            ["A", "", ""],
            ["A", "", "C"],
            
            ["Hello", "World"],
            ["stock.price"],
            
            // max length
            [String(repeating: "A", count: 255)],
            [String(repeating: "A", count: 255), String(repeating: "A", count: 255)],
            
            // this emoji counts as one character but it takes four bytes to store in utf8 
            [String(repeating: "😁", count: 63) + String("AAA")],
        ]
        
        for validRoute in validRoutes {
            XCTAssertNoThrow(try {
                let encoder = RoutingEncoder()
                var buffer = ByteBuffer()
                try encoder.encode(validRoute, into: &buffer)
                
                let decoder = RoutingDecoder()
                let decodedRoute = try decoder.decode(from: &buffer)
                
                XCTAssertEqual(validRoute, decodedRoute)
            }(), "Failed to encode/decode \(validRoute)")
        }
    }
    func testEncodingInvalidRoutes() {
        let invalidRoutes: [RouteMetadata] = [
            // too long
            [String(repeating: "A", count: 256)],
            [String(repeating: "A", count: 255), String(repeating: "A", count: 256)],
            
            // this emoji counts as one character but it takes four bytes to store in utf8 
            [String(repeating: "😁", count: 64)],
        ]
        
        for invalidRoute in invalidRoutes {
            let encoder = RoutingEncoder()
            var buffer = ByteBuffer()
            XCTAssertThrowsError(
                try encoder.encode(invalidRoute, into: &buffer), 
                "Did *not* fail to encode \(invalidRoute)"
            )
        }
    }
    
    func testDecodingInvalidRouteWithAnEmptyMessage() {
        var buffer = ByteBuffer()
        buffer.writeInteger(UInt8(1))
        
        let decoder = RoutingDecoder()
        XCTAssertThrowsError(try decoder.decode(from: &buffer))
    }
    func testDecodingInvalidRouteWithOneCharacterTooFew() {
        var buffer = ByteBuffer()
        buffer.writeInteger(UInt8(2))
        buffer.writeString("A")
        
        let decoder = RoutingDecoder()
        XCTAssertThrowsError(try decoder.decode(from: &buffer))
    }
}

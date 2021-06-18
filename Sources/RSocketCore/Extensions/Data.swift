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

import Foundation
import NIO

struct DataEncoder<Value> {
    var mimeType: MIMEType
    private var _encode: (Value) throws -> Data

    init(mimeType: MIMEType, encode: @escaping (Value) throws -> Data) {
        self._encode = encode
        self.mimeType = mimeType
    }

    func encode(_ value: Value) throws -> Data {
        try _encode(value)
    }
}

extension DataEncoder {
    func map<NewValue>(
        _ transform: @escaping (NewValue) throws -> Value
    ) -> DataEncoder<NewValue> {
        .init(mimeType: mimeType) { value in
            try _encode(try transform(value))
        }
    }
}

extension DataEncoder {
    static func json(
        type: Value.Type = Value.self,
        using encoder: JSONEncoder = .init()
    ) -> Self where Value: Encodable {
        .init(mimeType: .applicationJson, encode: encoder.encode(_:))
    }
}

struct DataDecoder<Value> {
    var mimeType: MIMEType
    private var _decode: (Data) throws -> Value

    init(mimeType: MIMEType, decode: @escaping (Data) throws -> Value) {
        self._decode = decode
        self.mimeType = mimeType
    }

    func decode(from data: Data) throws -> Value {
        try _decode(data)
    }
}

extension DataDecoder {
    func map<NewValue>(
        _ transform: @escaping (Value) throws -> NewValue
    ) -> DataDecoder<NewValue> {
        .init(mimeType: mimeType) { data in
            try transform(try _decode(data))
        }
    }
}

extension DataDecoder {
    static func json(
        type: Value.Type = Value.self,
        using decoder: JSONDecoder = .init()
    ) -> Self where Value: Decodable {
        self.init(mimeType: .applicationJson) { data in
            try decoder.decode(Value.self, from: data)
        }
    }
}

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

public struct AnyEncoder<Metadata, Data>: EncoderProtocol {
    @usableFromInline
    internal var _encoderBox: _AnyEncoderBase<Metadata, Data>
    
    @inlinable
    internal init<Encoder>(
        _ encoder: Encoder
    ) where Encoder: EncoderProtocol, Encoder.Metadata == Metadata, Encoder.Data == Data {
        _encoderBox = _AnyEncoderBox(encoder: encoder)
    }
    
    @inlinable
    mutating public func encode(
        metadata: Metadata,
        data: Data,
        encoding: ConnectionEncoding
    ) throws -> Payload {
        if !isKnownUniquelyReferenced(&_encoderBox) {
            _encoderBox = _encoderBox.copy()
        }
        return try _encoderBox.encode(metadata: metadata, data: data, encoding: encoding)
    }
}

extension AnyEncoder {
    @inlinable
    public func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { self }
}

extension EncoderProtocol {
    @inlinable
    public func eraseToAnyEncoder() -> AnyEncoder<Metadata, Data> { .init(self) }
}

@usableFromInline
internal class _AnyEncoderBase<Metadata, Data>: EncoderProtocol {
    @usableFromInline
    func encode(
        metadata: Metadata,
        data: Data,
        encoding: ConnectionEncoding
    ) throws -> Payload {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
    @usableFromInline
    func copy() -> _AnyEncoderBase<Metadata, Data> {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
}

@usableFromInline
final internal class _AnyEncoderBox<Encoder: EncoderProtocol>: _AnyEncoderBase<Encoder.Metadata, Encoder.Data> {
    @usableFromInline 
    internal var encoder: Encoder
    
    @usableFromInline 
    internal init(encoder: Encoder) {
        self.encoder = encoder
    }
    
    @usableFromInline 
    internal override func encode(
        metadata: Metadata,
        data: Data,
        encoding: ConnectionEncoding
    ) throws -> Payload {
        try encoder.encode(metadata: metadata, data: data, encoding: encoding)
    }
    
    @usableFromInline 
    internal override func copy() -> _AnyEncoderBase<Encoder.Metadata, Encoder.Data> {
        _AnyEncoderBox(encoder: encoder)
    }
}

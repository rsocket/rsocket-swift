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


public struct AnyDecoder<Metadata, Data>: DecoderProtocol {
    @usableFromInline
    internal var _decoderBox: _AnyDecoderBase<Metadata, Data>
    
    @inlinable
    internal init<Decoder>(
        _ decoder: Decoder
    ) where Decoder: DecoderProtocol, Decoder.Metadata == Metadata, Decoder.Data == Data {
        _decoderBox = _AnyDecoderBox(decoder: decoder)
    }
    
    @inlinable
    public mutating func decode(
        _ payload: Payload,
        encoding: ConnectionEncoding
    ) throws -> (Metadata, Data) {
        if !isKnownUniquelyReferenced(&_decoderBox) {
            _decoderBox = _decoderBox.copy()
        }
        return try _decoderBox.decode(payload, encoding: encoding)
    }
}

extension DecoderProtocol {
    @inlinable
    public func eraseToAnyDecoder() -> AnyDecoder<Metadata, Data> {
        .init(self)
    }
}

extension AnyDecoder {
    @inlinable
    public func eraseToAnyDecoder() -> AnyDecoder<Metadata, Data> { self }
}

@usableFromInline
internal class _AnyDecoderBase<Metadata, Data>: DecoderProtocol {
    @inlinable
    func decode(
        _ payload: Payload,
        encoding: ConnectionEncoding
    ) throws -> (Metadata, Data) {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
    @inlinable
    func copy() -> _AnyDecoderBase<Metadata, Data> {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
}

@usableFromInline
final internal class _AnyDecoderBox<Decoder: DecoderProtocol>: _AnyDecoderBase<Decoder.Metadata, Decoder.Data> {
    @usableFromInline
    internal var decoder: Decoder
    
    @usableFromInline
    internal init(decoder: Decoder) {
        self.decoder = decoder
    }
    
    @inlinable
    override internal func decode(
        _ payload: Payload,
        encoding: ConnectionEncoding
    ) throws -> (Decoder.Metadata, Decoder.Data) {
        try decoder.decode(payload, encoding: encoding)
    }
    
    @inlinable
    override internal func copy() -> _AnyDecoderBase<Decoder.Metadata, Decoder.Data> {
        _AnyDecoderBox(decoder: decoder)
    }
}

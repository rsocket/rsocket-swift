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


/// `ErasableMetadata` is a marker protocol used by `CoderBuilder`, `EncoderBuilder` or `DecoderBuilder` to automatically erase or preserve Metadata. 
/// If a type conforms to `ErasableMetadata` like `Data?` or `[CompositeMetadata]` and is the last Metadata, it is erased i.e. ignored by decoders and initialized with a default value by encoders. 
/// If Metadata is another type, it is automatically preserved and available by the caller i.e. when sending a request you also need to provide the metadata and the response contains the Metadata in addition to the Data. 
/// A user can always manually opt-out or opt-in by using ``preserveMetadata()`` or ``eraseMetadata()`` or ``setMetadata(_:)``.
public protocol ErasableMetadata {
    static var erasedValue: Self { get }
}

extension Optional: ErasableMetadata {
    public static var erasedValue: Optional<Wrapped> { nil }
}

extension Array: ErasableMetadata {
    public static var erasedValue: Array<Element> { [] }
}

public extension Decoders {
    struct EraseMetadata<Decoder>: DecoderProtocol where 
    Decoder: DecoderProtocol
    {
        var decoder: Decoder
        mutating public func decode(
            _ payload: Payload, 
            mimeType: ConnectionMIMEType
        ) throws -> (Void, Decoder.Data) {
            let (_, data) = try decoder.decode(payload, mimeType: mimeType)
            return ((), data)
        }
    }
    struct PreserveMetadata<Decoder>: DecoderProtocol where 
    Decoder: DecoderProtocol
    {
        var decoder: Decoder
        mutating public func decode(
            _ payload: Payload, 
            mimeType: ConnectionMIMEType
        ) throws -> (Void, (Decoder.Metadata, Decoder.Data)) {
            return ((), try decoder.decode(payload, mimeType: mimeType))
        }
    }
}

extension DecoderProtocol {
    func preserveMetadata() -> Decoders.PreserveMetadata<Self> {
        .init(decoder: self)
    }
    func eraseMetadata() -> Decoders.EraseMetadata<Self> {
        .init(decoder: self)
    }
}

public extension Encoders {
    struct EraseMetadata<Encoder>: EncoderProtocol where 
    Encoder: EncoderProtocol,
    Encoder.Metadata: ErasableMetadata
    {
        var encoder: Encoder
        public mutating func encode(
            metadata: Void, 
            data: Encoder.Data, 
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
                metadata: Encoder.Metadata.erasedValue, 
                data: data, 
                mimeType: mimeType
            )
        }
    }
    struct PreserveMetadata<Encoder>: EncoderProtocol where 
    Encoder: EncoderProtocol
    {
        var encoder: Encoder
        public mutating func encode(
            metadata: Void, 
            data: (Encoder.Metadata, Encoder.Data), 
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            let (metadata, data) = data
            return try encoder.encode(
                metadata: metadata, 
                data: data, 
                mimeType: mimeType
            )
        }
    }
    struct SetMetadata<Encoder>: EncoderProtocol where 
    Encoder: EncoderProtocol
    {
        var encoder: Encoder
        let metadata: Encoder.Metadata
        public mutating func encode(
            metadata: Void, 
            data: Encoder.Data, 
            mimeType: ConnectionMIMEType
        ) throws -> Payload {
            try encoder.encode(
                metadata: self.metadata, 
                data: data, 
                mimeType: mimeType
            )
        }
    }
}

public extension EncoderProtocol {
    func preserveMetadata() -> Encoders.PreserveMetadata<Self> {
        .init(encoder: self)
    }
    func eraseMetadata() -> Encoders.EraseMetadata<Self> where Metadata: ErasableMetadata {
        .init(encoder: self)
    }
    func setMetadata(_ metadata: Metadata) -> Encoders.SetMetadata<Self> {
        .init(encoder: self, metadata: metadata)
    }
}

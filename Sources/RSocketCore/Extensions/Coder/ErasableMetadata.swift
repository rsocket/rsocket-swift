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

extension Decoders {
    public struct EraseMetadata<Decoder>: DecoderProtocol where 
    Decoder: DecoderProtocol
    {
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal init(decoder: Decoder) {
            self.decoder = decoder
        }
        
        @inlinable
        mutating public func decode(
            _ payload: Payload, 
            encoding: ConnectionEncoding
        ) throws -> (Void, Decoder.Data) {
            let (_, data) = try decoder.decode(payload, encoding: encoding)
            return ((), data)
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func eraseMetadata() -> Decoders.EraseMetadata<Self> {
        .init(decoder: self)
    }
}


extension Decoders {
    public struct PreserveMetadata<Decoder>: DecoderProtocol where 
    Decoder: DecoderProtocol
    {
        @usableFromInline
        internal var decoder: Decoder
        
        @usableFromInline
        internal init(decoder: Decoder) {
            self.decoder = decoder
        }
        
        @inlinable
        mutating public func decode(
            _ payload: Payload, 
            encoding: ConnectionEncoding
        ) throws -> (Void, (Decoder.Metadata, Decoder.Data)) {
            return ((), try decoder.decode(payload, encoding: encoding))
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func preserveMetadata() -> Decoders.PreserveMetadata<Self> {
        .init(decoder: self)
    }
}


extension Encoders {
    public struct EraseMetadata<Encoder>: EncoderProtocol where 
    Encoder: EncoderProtocol,
    Encoder.Metadata: ErasableMetadata
    {
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal init(encoder: Encoder) {
            self.encoder = encoder
        }
        
        @inlinable
        public mutating func encode(
            metadata: Void, 
            data: Encoder.Data, 
            encoding: ConnectionEncoding
        ) throws -> Payload {
            try encoder.encode(
                metadata: Encoder.Metadata.erasedValue, 
                data: data, 
                encoding: encoding
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func eraseMetadata() -> Encoders.EraseMetadata<Self> where Metadata: ErasableMetadata {
        .init(encoder: self)
    }
}


extension Encoders {
    public struct PreserveMetadata<Encoder>: EncoderProtocol where 
    Encoder: EncoderProtocol
    {
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal init(encoder: Encoder) {
            self.encoder = encoder
        }
        
        @inlinable
        public mutating func encode(
            metadata: Void, 
            data: (Encoder.Metadata, Encoder.Data), 
            encoding: ConnectionEncoding
        ) throws -> Payload {
            let (metadata, data) = data
            return try encoder.encode(
                metadata: metadata, 
                data: data, 
                encoding: encoding
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func preserveMetadata() -> Encoders.PreserveMetadata<Self> {
        .init(encoder: self)
    }
}


extension Encoders {
    public struct SetMetadata<Encoder>: EncoderProtocol where 
    Encoder: EncoderProtocol
    {
        @usableFromInline
        internal var encoder: Encoder
        
        @usableFromInline
        internal let metadata: Encoder.Metadata
        
        @usableFromInline
        internal init(encoder: Encoder, metadata: Encoder.Metadata) {
            self.encoder = encoder
            self.metadata = metadata
        }
        
        @inlinable
        public mutating func encode(
            metadata: Void, 
            data: Encoder.Data, 
            encoding: ConnectionEncoding
        ) throws -> Payload {
            try encoder.encode(
                metadata: self.metadata, 
                data: data, 
                encoding: encoding
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func setMetadata(_ metadata: Metadata) -> Encoders.SetMetadata<Self> {
        .init(encoder: self, metadata: metadata)
    }
}

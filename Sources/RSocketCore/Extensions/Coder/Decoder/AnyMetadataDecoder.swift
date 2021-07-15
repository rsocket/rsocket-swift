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

import NIO

public struct AnyMetadataDecoder<Metadata>: MetadataDecoder {
    @usableFromInline
    internal var _decoderBox: _AnyMetadataDecoderBase<Metadata>
    
    @inlinable
    internal init<Decoder>(
        _ decoder: Decoder
    ) where Decoder: MetadataDecoder, Decoder.Metadata == Metadata {
        _decoderBox = _AnyMetadataDecoderBox(decoder: decoder)
    }
    
    @inlinable
    public var mimeType: MIMEType {
        _decoderBox.mimeType
    }
    @inlinable
    public func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        try _decoderBox.decode(from: &buffer)
    }
} 

extension MetadataDecoder {
    @inlinable
    public func eraseToAnyMetadataDecoder() -> AnyMetadataDecoder<Metadata> {
        .init(self)
    }
}

extension AnyMetadataDecoder {
    @inlinable
    public func eraseToAnyMetadataDecoder() -> AnyMetadataDecoder<Metadata> {
        self
    }
}

@usableFromInline
internal class _AnyMetadataDecoderBase<Metadata>: MetadataDecoder {
    @usableFromInline
    internal var mimeType: MIMEType {
        fatalError("\(#function) in \(Self.self) is an abstract property and needs to be overridden")
    }
    @usableFromInline
    internal func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
}

@usableFromInline
final internal class _AnyMetadataDecoderBox<Decoder: MetadataDecoder>: _AnyMetadataDecoderBase<Decoder.Metadata> {
    @usableFromInline
    internal var decoder: Decoder
    
    @usableFromInline
    internal init(decoder: Decoder) {
        self.decoder = decoder
    }
    
    @usableFromInline
    internal override var mimeType: MIMEType {
        decoder.mimeType
    }
    
    @usableFromInline
    internal override func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        try decoder.decode(from: &buffer)
    }
}

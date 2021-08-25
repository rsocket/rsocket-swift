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

import NIOCore

public struct AnyMetadataEncoder<Metadata>: MetadataEncoder {
    @usableFromInline
    internal var _encoderBox: _AnyMetadataEncoderBase<Metadata>
    
    @inlinable
    internal init<Encoder>(
        _ encoder: Encoder
    ) where Encoder: MetadataEncoder, Encoder.Metadata == Metadata {
        _encoderBox = _AnyMetadataEncoderBox(encoder: encoder)
    }
    
    @inlinable
    public var mimeType: MIMEType { 
        _encoderBox.mimeType
    }
    
    @inlinable
    public func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        try _encoderBox.encode(metadata, into: &buffer)
    }
}

extension MetadataEncoder {
    @inlinable
    public func eraseToAnyMetadataEncoder() -> AnyMetadataEncoder<Metadata> {
        .init(self)
    }
}

extension AnyMetadataEncoder {
    @inlinable
    public func eraseToAnyMetadataEncoder() -> AnyMetadataEncoder<Metadata> {
        self
    }
}

@usableFromInline
internal class _AnyMetadataEncoderBase<Metadata>: MetadataEncoder {
    @usableFromInline
    internal var mimeType: MIMEType {
        fatalError("\(#function) in \(Self.self) is an abstract property and needs to be overridden")
    }
    
    @usableFromInline
    internal func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        fatalError("\(#function) in \(Self.self) is an abstract method and needs to be overridden")
    }
}

@usableFromInline
final internal class _AnyMetadataEncoderBox<Encoder: MetadataEncoder>: _AnyMetadataEncoderBase<Encoder.Metadata> {
    @usableFromInline 
    internal var encoder: Encoder
    
    @usableFromInline 
    internal init(encoder: Encoder) {
        self.encoder = encoder
    }
    
    @usableFromInline
    internal override var mimeType: MIMEType {
        encoder.mimeType
    }
    
    @usableFromInline
    internal override func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        try encoder.encode(metadata, into: &buffer)
    }
}

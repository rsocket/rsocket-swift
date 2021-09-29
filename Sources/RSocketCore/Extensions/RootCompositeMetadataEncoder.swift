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

public struct RootCompositeMetadataEncoder: MetadataEncoder {
    public typealias Metadata = [CompositeMetadata]
    
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    
    @usableFromInline
    internal let mimeTypeEncoder: MIMETypeEncoder
    
    @inlinable
    public init(mimeTypeEncoder: MIMETypeEncoder = MIMETypeEncoder()) {
        self.mimeTypeEncoder = mimeTypeEncoder
    }
    
    @inlinable
    public func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws {
        for compositeMetadata in metadata {
            try encodeSingleCompositeMetadata(compositeMetadata, into: &buffer)
        }
    }
    
    @inlinable
    internal func encodeSingleCompositeMetadata(
        _ metadata: CompositeMetadata, 
        into buffer: inout ByteBuffer
    ) throws {
        try mimeTypeEncoder.encode(metadata.mimeType, into: &buffer)
        var data = metadata.data
        try buffer.writeUInt24WithBoundsCheck(data.readableBytes)
        buffer.writeBuffer(&data)
    }
}

// Swift 5.5 does support static member lookup in a generic context: https://github.com/apple/swift-evolution/blob/main/proposals/0299-extend-generic-static-member-lookup.md
public extension MetadataEncoder where Self == RootCompositeMetadataEncoder {
    static var compositeMetadata: Self { .init() }
}

extension CompositeMetadata {
    @inlinable
    public static func encoded<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) throws -> Self where Encoder: MetadataEncoder {
        CompositeMetadata(
            mimeType: encoder.mimeType,
            data: try encoder.encode(metadata)
        )
    }
}

extension RangeReplaceableCollection where Element == CompositeMetadata {
    @usableFromInline
    func encoded<Encoder>(
        _ metadata: Encoder.Metadata,
        using encoder: Encoder
    ) throws -> Self where Encoder: MetadataEncoder {
        self + CollectionOfOne(try CompositeMetadata.encoded(metadata, using: encoder))
    }
}

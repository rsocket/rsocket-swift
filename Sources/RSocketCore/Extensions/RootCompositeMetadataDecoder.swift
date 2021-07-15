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

// MARK: Root Composite Metadata Decoder

public struct RootCompositeMetadataDecoder: MetadataDecoder {
    public typealias Metadata = [CompositeMetadata]
    
    @inlinable
    public var mimeType: MIMEType { .messageXRSocketCompositeMetadataV0 }
    
    @usableFromInline
    internal let mimeTypeDecoder: MIMETypeEncoder
    
    @inlinable
    public init(mimeTypeDecoder: MIMETypeEncoder = MIMETypeEncoder()) {
        self.mimeTypeDecoder = mimeTypeDecoder
    }
    
    @inlinable
    public func decode(from buffer: inout ByteBuffer) throws -> Metadata {
        fatalError("not implemented")
    }
}

public extension MetadataDecoder where Self == RootCompositeMetadataDecoder {
    static var compositeMetadata: Self { .init() }
}

extension Sequence where Element == CompositeMetadata {
    @inlinable
    func decodeFirstIfPresent<Decoder>(
        using decoder: Decoder
    ) throws -> Decoder.Metadata? where Decoder: MetadataDecoder {
        guard let data = first(where: { $0.mimeType == decoder.mimeType })?.data else {
            return nil
        }
        return try decoder.decode(from: data)
    }
    @inlinable
    func decodeFirst<Decoder>(
        using decoder: Decoder
    ) throws -> Decoder.Metadata where Decoder: MetadataDecoder {
        guard let metadata = try decodeFirstIfPresent(using: decoder) else {
            throw Error.invalid(message: "required Metadata not present for \(decoder.mimeType)")
        }
        return metadata
    }
}

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

public protocol MetadataDecodable {
    func decodeMetadata<Decoder>(
        using metadataDecoder: Decoder
    ) throws -> Decoder.Metadata where Decoder: MetadataDecoder 
}


extension Data: MetadataDecodable {
    @inlinable
    public func decodeMetadata<Decoder>(
        using metadataDecoder: Decoder
    ) throws -> Decoder.Metadata where Decoder : MetadataDecoder {
        try metadataDecoder.decode(from: self)
    }
}

extension Optional: MetadataDecodable where Wrapped: MetadataDecodable {
    @inlinable
    public func decodeMetadata<Decoder>(
        using metadataDecoder: Decoder
    ) throws -> Decoder.Metadata where Decoder : MetadataDecoder {
        guard let self = self else {
            throw Error.invalid(message: "Metadata is nil an therefore can not be decoded as \(Decoder.Metadata.self) using \(Decoder.self)")
        }
        return try self.decodeMetadata(using: metadataDecoder)
    }
}

extension Array: MetadataDecodable where Element == CompositeMetadata {
    @inlinable
    public func decodeMetadata<Decoder>(
        using metadataDecoder: Decoder
    ) throws -> Decoder.Metadata where Decoder : MetadataDecoder {
        try self.decodeFirst(using: metadataDecoder)
    }
}

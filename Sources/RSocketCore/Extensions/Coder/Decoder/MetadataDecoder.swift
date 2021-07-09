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
import Foundation

public protocol MetadataEncoder: CompositeMetadataEncoder {
    associatedtype Metadata
    var mimeType: MIMEType { get }
    func encode(_ metadata: Metadata, into buffer: inout ByteBuffer) throws
}

extension MetadataEncoder {
    @inlinable
    func encode(_ metadata: Metadata) throws -> Data {
        var buffer = ByteBuffer()
        try self.encode(metadata, into: &buffer)
        return buffer.readData(length: buffer.readableBytes) ?? Data()
    }
}

extension MetadataEncoder {
    @inlinable
    public func encodeMetadata(_ metadata: Metadata) throws -> [CompositeMetadata] {
        [try CompositeMetadata.encoded(metadata, using: self)]
    }
}

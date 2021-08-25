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
import NIO

public struct OctetStreamMetadataEncoder: MetadataEncoder {
    public typealias Metadata = Data?

    @inlinable
    public init() {}

    @inlinable
    public var mimeType: MIMEType { .applicationOctetStream }

    @inlinable
    public func encode(_ metadata: Data?, into buffer: inout ByteBuffer) throws {
        guard let metadata = metadata else { return }
        buffer.writeData(metadata)
    }
}

extension MetadataEncoder where Self == OctetStreamMetadataEncoder {
    @inlinable
    public static var octetStream: Self { .init() }
}

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

internal struct RequestFireAndForgetFrameEncoder: FrameEncoding {
    private let headerEncoder: FrameHeaderEncoding

    private let payloadEncoder: PayloadEncoding

    internal init(
        headerEncoder: FrameHeaderEncoding = FrameHeaderEncoder(),
        payloadEncoder: PayloadEncoding = PayloadEncoder()
    ) {
        self.headerEncoder = headerEncoder
        self.payloadEncoder = payloadEncoder
    }

    internal func encode(frame: RequestFireAndForgetFrame, using allocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = try headerEncoder.encode(header: frame.header, using: allocator)
        try payloadEncoder.encode(payload: frame.payload, to: &buffer)
        return buffer
    }
}

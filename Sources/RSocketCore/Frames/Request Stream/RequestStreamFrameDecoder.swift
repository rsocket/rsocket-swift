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

internal struct RequestStreamFrameDecoder: FrameDecoding {
    private let payloadDecoder: PayloadDecoding

    internal init(payloadDecoder: PayloadDecoding = PayloadDecoder()) {
        self.payloadDecoder = payloadDecoder
    }

    internal func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> RequestStreamFrame {
        guard let initialRequestN: Int32 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        let payload = try payloadDecoder.decode(from: &buffer, hasMetadata: header.flags.contains(.metadata))
        return RequestStreamFrame(
            header: header,
            initialRequestN: initialRequestN,
            payload: payload
        )
    }
}

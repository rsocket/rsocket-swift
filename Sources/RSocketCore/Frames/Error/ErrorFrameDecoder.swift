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

public struct ErrorFrameDecoder: FrameDecoder {
    public func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> ErrorFrame {
        guard let codeValue: UInt32 = buffer.readInteger() else {
            throw FrameError.tooSmall
        }
        let errorCode = ErrorCode(rawValue: codeValue)
        let errorData: String
        if buffer.readableBytes > 0 {
            guard let string = buffer.readString(length: buffer.readableBytes) else {
                throw FrameError.stringContainsInvalidCharacters
            }
            errorData = string
        } else {
            errorData = ""
        }
        return ErrorFrame(
            header: header,
            errorCode: errorCode,
            errorData: errorData
        )
    }
}

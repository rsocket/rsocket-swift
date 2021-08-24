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

internal struct ResumeFrameBodyEncoder: FrameBodyEncoding {
    internal func encode(frame: ResumeFrameBody, into buffer: inout ByteBuffer) throws {
        buffer.writeInteger(frame.version.major)
        buffer.writeInteger(frame.version.minor)
        var token = frame.resumeIdentificationToken
        guard token.readableBytes <= UInt16.max else {
            throw Error.connectionError(message: "resumeIdentificationToken is too big")
        }
        buffer.writeInteger(UInt16(token.readableBytes))
        buffer.writeBuffer(&token)
        buffer.writeInteger(frame.lastReceivedServerPosition)
        buffer.writeInteger(frame.firstAvailableClientPosition)
    }
}

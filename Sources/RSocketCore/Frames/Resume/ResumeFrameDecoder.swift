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

internal struct ResumeFrameDecoder: FrameDecoding {
    internal func decode(header: FrameHeader, buffer: inout ByteBuffer) throws -> ResumeFrame {
        guard let majorVersion: UInt16 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let minorVersion: UInt16 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let resumeTokenLength: UInt16 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let resumeIdentificationToken = buffer.readData(length: Int(resumeTokenLength)) else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let lastReceivedServerPosition: Int64 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        guard let firstAvailableClientPosition: Int64 = buffer.readInteger() else {
            throw Error.connectionError(message: "Frame is not big enough")
        }
        return ResumeFrame(
            header: header,
            majorVersion: majorVersion,
            minorVersion: minorVersion,
            resumeIdentificationToken: resumeIdentificationToken,
            lastReceivedServerPosition: lastReceivedServerPosition,
            firstAvailableClientPosition: firstAvailableClientPosition
        )
    }
}

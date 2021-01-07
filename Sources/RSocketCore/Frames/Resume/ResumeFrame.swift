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

/**
 The `RESUME` frame is sent by the client to resume the connection

 It replaces the `SETUP` frame.
 */
internal struct ResumeFrame {
    /// The header of this frame
    internal let header: FrameHeader

    /// Major version number of the protocol
    internal let majorVersion: UInt16

    /// Minor version number of the protocol
    internal let minorVersion: UInt16

    /// Token used for client resume identification
    internal let resumeIdentificationToken: Data

    /// The last implied position the client received from the server
    internal let lastReceivedServerPosition: Int64

    /// The earliest position that the client can rewind back to prior to resending frames
    internal let firstAvailableClientPosition: Int64

    internal init(
        header: FrameHeader,
        majorVersion: UInt16,
        minorVersion: UInt16,
        resumeIdentificationToken: Data,
        lastReceivedServerPosition: Int64,
        firstAvailableClientPosition: Int64
    ) {
        self.header = header
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.resumeIdentificationToken = resumeIdentificationToken
        self.lastReceivedServerPosition = lastReceivedServerPosition
        self.firstAvailableClientPosition = firstAvailableClientPosition
    }

    internal init(
        majorVersion: UInt16,
        minorVersion: UInt16,
        resumeIdentificationToken: Data,
        lastReceivedServerPosition: Int64,
        firstAvailableClientPosition: Int64
    ) {
        self.header = FrameHeader(streamId: 0, type: .resume, flags: [])
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.resumeIdentificationToken = resumeIdentificationToken
        self.lastReceivedServerPosition = lastReceivedServerPosition
        self.firstAvailableClientPosition = firstAvailableClientPosition
    }
}

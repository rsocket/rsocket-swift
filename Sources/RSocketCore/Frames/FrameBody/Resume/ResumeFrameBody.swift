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

/**
 The `RESUME` frame is sent by the client to resume the connection

 It replaces the `SETUP` frame.
 */
internal struct ResumeFrameBody: Hashable {
    /// version of the client protocol implementation
    internal var version: Version

    /// Token used for client resume identification
    internal var resumeIdentificationToken: ByteBuffer

    /// The last implied position the client received from the server
    internal var lastReceivedServerPosition: Int64

    /// The earliest position that the client can rewind back to prior to resending frames
    internal var firstAvailableClientPosition: Int64
}

extension ResumeFrameBody: FrameBodyBoundToConnection {
    func body() -> FrameBody { .resume(self) }
    func header() -> FrameHeader {
        FrameHeader(streamId: .connection, type: .resume, flags: [])
    }
}

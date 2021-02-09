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

protocol FrameHandler {
    func handle(header: FrameHeader, frameBuffer: ByteBuffer)
}

protocol StreamHandler {
    func handleNext(header: FrameHeader, frameBuffer: ByteBuffer)
    func handle(error: Error)
    func handleComplete()
    func handleCancel()
    func handle(requestN: Int32)
}

internal struct Responder: FrameHandler {

    private let connection: DuplexConnection

    // TODO: thread safety
    private var activeStreams: [Int32: StreamHandler] = [:]

    init(connection: DuplexConnection) {
        self.connection = connection
    }

    func handle(header: FrameHeader, frameBuffer: ByteBuffer) {

    }
}






//    func handle(frame: CancelFrame)
//    func handle(frame: ErrorFrame)
//    func handle(frame: ExtensionFrame)
//    func handle(frame: KeepAliveFrame)
//    func handle(frame: LeaseFrame)
//    func handle(frame: MetadataPushFrame)
//    func handle(frame: PayloadFrame)
//    func handle(frame: RequestChannelFrame)
//    func handle(frame: RequestFireAndForgetFrame)
//    func handle(frame: RequestNFrame)
//    func handle(frame: RequestResponseFrame)
//    func handle(frame: RequestStreamFrame)
//    func handle(frame: ResumeFrame)
//    func handle(frame: ResumeOkFrame)
//    func handle(frame: SetupFrame)

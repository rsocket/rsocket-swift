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

internal final class Responder {
    private let responderSocket: RSocket
    private let sendFrame: (Frame) -> Void
    private var activeStreams: [StreamID: ResponderStream] = [:]
    private let eventLoop: EventLoop
    internal init(
        responderSocket: RSocket,
        eventLoop: EventLoop,
        sendFrame: @escaping (Frame) -> Void
    ) {
        self.responderSocket = responderSocket
        self.sendFrame = sendFrame
        self.eventLoop = eventLoop
    }

    internal func receiveInbound(frame: Frame) {
        let streamId = frame.header.streamId
        if let existingStreamAdapter = activeStreams[streamId] {
            existingStreamAdapter.receive(frame: frame)
            return
        }
        
        guard frame.header.type.canCreateStream else {
            // ignore frame because it could be a late frame
            return
        }

        let stream = ResponderStream(
            id: streamId,
            responderSocket: responderSocket,
            eventLoop: eventLoop,
            delegate: self
        )
        activeStreams[streamId] = stream
        stream.receive(frame: frame)
    }
}

extension Responder: StreamDelegate {
    internal func send(frame: Frame) {
        sendFrame(frame)
    }
    func terminate(streamId: StreamID) {
        activeStreams.removeValue(forKey: streamId)
    }
}

extension FrameType {
    /// returns true for all request frame types, false otherwise
    fileprivate var canCreateStream: Bool {
        switch self {
        case .requestFnf,
             .requestResponse,
             .requestStream,
             .requestChannel:
            return true
        default: return false
        }
    }
}

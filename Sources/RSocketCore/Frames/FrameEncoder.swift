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

internal protocol FrameEncoding {
    func encode(frame: Frame, into buffer: inout ByteBuffer) throws
}

internal struct FrameEncoder: FrameEncoding {
    private let headerEncoder = FrameHeaderEncoder()
    private let setupEncoder = SetupFrameBodyEncoder()
    private let leaseEncoder = LeaseFrameBodyEncoder()
    private let keepAliveEncoder = KeepAliveFrameBodyEncoder()
    private let requestResponseEncoder = RequestResponseFrameBodyEncoder()
    private let requestFireAndForgetEncoder = RequestFireAndForgetFrameBodyEncoder()
    private let requestStreamEncoder = RequestStreamFrameBodyEncoder()
    private let requestChannelEncoder = RequestChannelFrameBodyEncoder()
    private let requestNEncoder = RequestNFrameBodyEncoder()
    private let cancelEncoder = CancelFrameBodyEncoder()
    private let payloadEncoder = PayloadFrameBodyEncoder()
    private let errorEncoder = ErrorFrameBodyEncoder()
    private let metadataPushEncoder = MetadataPushFrameBodyEncoder()
    private let resumeEncoder = ResumeFrameBodyEncoder()
    private let resumeOkEncoder = ResumeOkFrameBodyEncoder()
    private let extensionEncoder = ExtensionFrameBodyEncoder()

    internal func encode(frame: Frame, into buffer: inout ByteBuffer) throws {
        try headerEncoder.encode(header: frame.makeHeader(), into: &buffer)
        switch frame.body {
        case let .setup(body):
            try setupEncoder.encode(frame: body, into: &buffer)

        case let .lease(body):
            try leaseEncoder.encode(frame: body, into: &buffer)

        case let .keepalive(body):
            try keepAliveEncoder.encode(frame: body, into: &buffer)

        case let .requestResponse(body):
            try requestResponseEncoder.encode(frame: body, into: &buffer)

        case let .requestFnf(body):
            try requestFireAndForgetEncoder.encode(frame: body, into: &buffer)

        case let .requestStream(body):
            try requestStreamEncoder.encode(frame: body, into: &buffer)

        case let .requestChannel(body):
            try requestChannelEncoder.encode(frame: body, into: &buffer)

        case let .requestN(body):
            try requestNEncoder.encode(frame: body, into: &buffer)

        case let .cancel(body):
            try cancelEncoder.encode(frame: body, into: &buffer)

        case let .payload(body):
            try payloadEncoder.encode(frame: body, into: &buffer)

        case let .error(body):
            try errorEncoder.encode(frame: body, into: &buffer)

        case let .metadataPush(body):
            try metadataPushEncoder.encode(frame: body, into: &buffer)

        case let .resume(body):
            try resumeEncoder.encode(frame: body, into: &buffer)

        case let .resumeOk(body):
            try resumeOkEncoder.encode(frame: body, into: &buffer)

        case let .ext(body):
            try extensionEncoder.encode(frame: body, into: &buffer)
        }
    }
}

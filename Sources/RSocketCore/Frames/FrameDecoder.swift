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

internal protocol FrameDecoding {
    func decode(from buffer: inout ByteBuffer) throws -> Frame
}

internal struct FrameDecoder: FrameDecoding {
    enum Error: Swift.Error {
        case unsupportedFrameType
    }

    private let headerDecoder = FrameHeaderDecoder()
    private let setupDecoder = SetupFrameBodyDecoder()
    private let leaseDecoder = LeaseFrameBodyDecoder()
    private let keepAliveDecoder = KeepAliveFrameBodyDecoder()
    private let requestResponseDecoder = RequestResponseFrameBodyDecoder()
    private let requestFireAndForgetDecoder = RequestFireAndForgetFrameBodyDecoder()
    private let requestStreamDecoder = RequestStreamFrameBodyDecoder()
    private let requestChannelDecoder = RequestChannelFrameBodyDecoder()
    private let requestNDecoder = RequestNFrameBodyDecoder()
    private let cancelDecoder = CancelFrameBodyDecoder()
    private let payloadDecoder = PayloadFrameBodyDecoder()
    private let errorDecoder = ErrorFrameBodyDecoder()
    private let metadataPushDecoder = MetadataPushFrameBodyDecoder()
    private let resumeDecoder = ResumeFrameBodyDecoder()
    private let resumeOkDecoder = ResumeOkFrameBodyDecoder()
    private let extensionDecoder = ExtensionFrameBodyDecoder()

    internal func decode(from buffer: inout ByteBuffer) throws -> Frame {
        let header = try headerDecoder.decode(buffer: &buffer)
        let body: FrameBody
        switch header.type {
        case .reserved:
            throw Error.unsupportedFrameType

        case .setup:
            body = .setup(try setupDecoder.decode(from: &buffer, header: header))

        case .lease:
            body = .lease(try leaseDecoder.decode(from: &buffer, header: header))

        case .keepalive:
            body = .keepalive(try keepAliveDecoder.decode(from: &buffer, header: header))

        case .requestResponse:
            body = .requestResponse(try requestResponseDecoder.decode(from: &buffer, header: header))

        case .requestFnf:
            body = .requestFnf(try requestFireAndForgetDecoder.decode(from: &buffer, header: header))

        case .requestStream:
            body = .requestStream(try requestStreamDecoder.decode(from: &buffer, header: header))

        case .requestChannel:
            body = .requestChannel(try requestChannelDecoder.decode(from: &buffer, header: header))

        case .requestN:
            body = .requestN(try requestNDecoder.decode(from: &buffer, header: header))

        case .cancel:
            body = .cancel(try cancelDecoder.decode(from: &buffer, header: header))

        case .payload:
            body = .payload(try payloadDecoder.decode(from: &buffer, header: header))

        case .error:
            body = .error(try errorDecoder.decode(from: &buffer, header: header))

        case .metadataPush:
            body = .metadataPush(try metadataPushDecoder.decode(from: &buffer, header: header))

        case .resume:
            body = .resume(try resumeDecoder.decode(from: &buffer, header: header))

        case .resumeOk:
            body = .resumeOk(try resumeOkDecoder.decode(from: &buffer, header: header))

        case .ext:
            body = .ext(try extensionDecoder.decode(from: &buffer, header: header))
        }
        return Frame(header: header, body: body)
    }
}

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
            body = try setupDecoder.decode(from: &buffer, header: header).body()

        case .lease:
            body = try leaseDecoder.decode(from: &buffer, header: header).body()

        case .keepalive:
            body = try keepAliveDecoder.decode(from: &buffer, header: header).body()

        case .requestResponse:
            body = try requestResponseDecoder.decode(from: &buffer, header: header).body()

        case .requestFnf:
            body = try requestFireAndForgetDecoder.decode(from: &buffer, header: header).body()

        case .requestStream:
            body = try requestStreamDecoder.decode(from: &buffer, header: header).body()

        case .requestChannel:
            body = try requestChannelDecoder.decode(from: &buffer, header: header).body()

        case .requestN:
            body = try requestNDecoder.decode(from: &buffer, header: header).body()

        case .cancel:
            body = try cancelDecoder.decode(from: &buffer, header: header).body()

        case .payload:
            body = try payloadDecoder.decode(from: &buffer, header: header).body()

        case .error:
            body = try errorDecoder.decode(from: &buffer, header: header).body()

        case .metadataPush:
            body = try metadataPushDecoder.decode(from: &buffer, header: header).body()

        case .resume:
            body = try resumeDecoder.decode(from: &buffer, header: header).body()

        case .resumeOk:
            body = try resumeOkDecoder.decode(from: &buffer, header: header).body()

        case .ext:
            body = try extensionDecoder.decode(from: &buffer, header: header).body()
        }
        return Frame(streamId: header.streamId, body: body)
    }
}

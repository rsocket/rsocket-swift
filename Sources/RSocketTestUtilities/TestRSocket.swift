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

import XCTest
import NIO
import RSocketCore

public final class TestRSocket: RSocket {
    public var metadataPush: ((Data) -> ())? = nil
    public var fireAndForget: ((_ payload: Payload) -> ())? = nil
    public var requestResponse: ((_ payload: Payload, _ responderOutput: Promise) -> Cancellable)? = nil
    public var stream: ((_ payload: Payload, _ initialRequestN: Int32, _ responderOutput: UnidirectionalStream) -> Subscription)? = nil
    public var channel: ((_ payload: Payload, _ initialRequestN: Int32, _ isCompleted: Bool, _ responderOutput: UnidirectionalStream) -> UnidirectionalStream)? = nil
    
    private let file: StaticString
    private let line: UInt
    
    public init(
        metadataPush: ((Data) -> ())? = nil,
        fireAndForget: ((Payload) -> ())? = nil,
        requestResponse: ((Payload, Promise) -> Cancellable)? = nil,
        stream: ((Payload, Int32, UnidirectionalStream) -> Subscription)? = nil,
        channel: ((Payload, Int32, Bool, UnidirectionalStream) -> UnidirectionalStream)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.metadataPush = metadataPush
        self.fireAndForget = fireAndForget
        self.requestResponse = requestResponse
        self.stream = stream
        self.channel = channel
        self.file = file
        self.line = line
    }
    
    
    public func metadataPush(metadata: Data) {
        guard let metadataPush = metadataPush else {
            XCTFail("metadataPush not expected to be called ", file: file, line: line)
            return
        }
        metadataPush(metadata)
    }
    
    public func fireAndForget(payload: Payload) {
        guard let fireAndForget = fireAndForget else {
            XCTFail("fireAndForget not expected to be called ", file: file, line: line)
            return
        }
        fireAndForget(payload)
    }
    
    public func requestResponse(payload: Payload, responderPromise: Promise) -> Cancellable {
        guard let requestResponse = requestResponse else {
            XCTFail("requestResponse not expected to be called ", file: file, line: line)
            return TestUnidirectionalStream()
        }
        return requestResponse(payload, responderPromise)
    }
    
    public func stream(payload: Payload, initialRequestN: Int32, responderStream: UnidirectionalStream) -> Subscription {
        guard let stream = stream else {
            XCTFail("stream not expected to be called ", file: file, line: line)
            return TestUnidirectionalStream()
        }
        return stream(payload, initialRequestN, responderStream)
    }
    
    public func channel(payload: Payload, initialRequestN: Int32, isCompleted: Bool, responderStream: UnidirectionalStream) -> UnidirectionalStream {
        guard let channel = channel else {
            XCTFail("channel not expected to be called ", file: file, line: line)
            return TestUnidirectionalStream()
        }
        return channel(payload, initialRequestN, isCompleted, responderStream)
    }
}

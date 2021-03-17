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

import RSocketCore
import ReactiveSwift
import Foundation
import RSocketReactiveSwift

final class TestRSocket: RSocketReactiveSwift.RSocket {
    var metadataPushCallback: (Data) -> () = { _ in }
    var fireAndForgetCallback: (Payload) -> () = { _ in }
    var requestResponseCallback: (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never }
    var requestStreamCallback: (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never }
    var requestChannelCallback: (Payload, SignalProducer<Payload, Swift.Error>?) -> SignalProducer<Payload, Swift.Error> = { _, _ in .never }
    
    internal init(
        metadataPush: @escaping (Data) -> () = { _ in },
        fireAndForget: @escaping (Payload) -> () = { _ in },
        requestResponse: @escaping (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never },
        requestStream: @escaping (Payload) -> SignalProducer<Payload, Swift.Error> = { _ in .never },
        requestChannel: @escaping (Payload, SignalProducer<Payload, Swift.Error>?) -> SignalProducer<Payload, Swift.Error> = { _, _ in .never }
    ) {
        self.metadataPushCallback = metadataPush
        self.fireAndForgetCallback = fireAndForget
        self.requestResponseCallback = requestResponse
        self.requestStreamCallback = requestStream
        self.requestChannelCallback = requestChannel
    }
    
    func metadataPush(metadata: Data) { metadataPushCallback(metadata) }
    func fireAndForget(payload: Payload) { fireAndForgetCallback(payload) }
    func requestResponse(payload: Payload) -> SignalProducer<Payload, Swift.Error> { requestResponseCallback(payload) }
    func requestStream(payload: Payload) -> SignalProducer<Payload, Swift.Error> { requestStreamCallback(payload) }
    func requestChannel(payload: Payload, payloadProducer: SignalProducer<Payload, Swift.Error>?) -> SignalProducer<Payload, Swift.Error> { requestChannelCallback(payload, payloadProducer) }
}

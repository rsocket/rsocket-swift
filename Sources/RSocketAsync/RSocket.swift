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

#if compiler(>=5.5)
import Foundation
import RSocketCore

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public protocol RSocket {
    func metadataPush(metadata: Data)
    func fireAndForget(payload: Payload)
    func requestResponse(payload: Payload) async throws -> Payload
    func requestStream(payload: Payload) -> AsyncThrowingStream<Payload, Swift.Error>
    func requestChannel<PayloadSequence>(
        initialPayload: Payload, 
        payloadStream: PayloadSequence?
    ) -> AsyncThrowingStream<Payload, Swift.Error> 
    where PayloadSequence: AsyncSequence, PayloadSequence.Element == Payload
}

#endif

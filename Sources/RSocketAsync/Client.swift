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
import RSocketCore

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
public struct AsyncClient {
    private let coreClient: RSocketCore.CoreClient

    public var requester: RequesterRSocket { RequesterRSocket(requester: coreClient.requester) }

    public init(_ coreClient: RSocketCore.CoreClient) {
        self.coreClient = coreClient
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension RSocketCore.ClientBootstrap where Client == CoreClient, Responder == RSocketCore.RSocket  {
    public func connect(to endpoint: Transport.Endpoint, payload: Payload) async throws -> AsyncClient {
        AsyncClient(try await connect(to: endpoint, payload: payload, responder: nil).get())
    }
}

#endif

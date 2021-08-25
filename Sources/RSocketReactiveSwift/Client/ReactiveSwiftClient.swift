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

public struct ReactiveSwiftClient: Client {
    private let coreClient: CoreClient

    public var requester: RSocketReactiveSwift.RequesterRSocket { RequesterAdapter(requester: coreClient.requester) }

    public init(_ coreClient: CoreClient) {
        self.coreClient = coreClient
    }
}

extension ClientBootstrap where Client == CoreClient, Responder == RSocketCore.RSocket  {
    public func connect(
        to endpoint: Transport.Endpoint,
        payload: Payload = .empty,
        responder: RSocketReactiveSwift.ResponderRSocket? = nil
    ) -> SignalProducer<ReactiveSwiftClient, Swift.Error> {
        SignalProducer { observer, lifetime in
            let responder = responder.map { ResponderAdapter(responder: $0, encoding: config.encoding) }
            let future = connect(to: endpoint, payload: payload, responder: responder)
                .map(ReactiveSwiftClient.init)
            future.whenComplete { result in
                switch result {
                case let .success(client):
                    observer.send(value: client)
                    observer.sendCompleted()
                case let .failure(error):
                    observer.send(error: error)
                }
            }
        }
    }
}

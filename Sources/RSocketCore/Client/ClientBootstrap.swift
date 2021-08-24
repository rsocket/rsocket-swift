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

public protocol ClientBootstrap {
    associatedtype Client
    associatedtype Responder
    associatedtype Transport: TransportChannelHandler
    
    /// Creates a new connection to the given `endpoint`.
    /// - Parameters:
    ///   - endpoint: endpoint to connect to
    ///   - payload: user defined `Payload` which is send in the initial setup frame
    ///   - responder: responder which is used to accept incoming requests. Defaults to a responder which rejects all incoming requests
    func connect(
        to endpoint: Transport.Endpoint,
        payload: Payload,
        responder: Responder?
    ) -> EventLoopFuture<Client>
}

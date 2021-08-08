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

import Foundation

public protocol RSocket {
    func metadataPush(metadata: Data)
    
    func fireAndForget(payload: Payload)
    
    func requestResponse(
        payload: Payload, 
        responderPromise: Subscriber & Cancellable & Extendable
    ) -> Cancellable & Extendable
    
    func stream(
        payload: Payload, 
        initialRequestN: Int32, 
        responderStream: Subscriber & Cancellable & Subscription
    ) -> Subscription & Extendable
    
    func channel(
        payload: Payload, 
        initialRequestN: Int32, 
        isCompleted: Bool, 
        responderStream: Subscriber & Cancellable & Subscription & Extendable
    ) -> Subscriber & Cancellable & Subscription & Extendable
}

public typealias Promise = Subscriber & Cancellable & Extendable

public typealias UnidirectionalStream =  Subscriber & Cancellable & Subscription & Extendable


protocol _RSocket {
    func metadataPush(metadata: Data, completable: Completable) -> Cancellable
    
    func fireAndForget(payload: Payload, completable: Completable) -> Cancellable
    
    func requestResponse(
        payload: Payload, 
        delegate: _Subscriber & Cancellable
    ) -> Cancellable
    
    func stream(
        payload: Payload, 
        initialRequestN: Int32, 
        delegate: Producer & Cancellable & Completable
    ) -> Subscription & Cancellable
    
    func channel(
        payload: Payload, 
        initialRequestN: Int32, 
        isCompleted: Bool, 
        delegate: Producer & Cancellable & Completable
    ) -> Producer & Cancellable & Completable
}

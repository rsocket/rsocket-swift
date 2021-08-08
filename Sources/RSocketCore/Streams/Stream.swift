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

//public protocol Cancellable {
//    func onCancel()
//    func onError(_ error: Error)
//    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool)
//}
//
//public protocol Promise: Cancellable {
//    func onNext(_ payload: Payload)
//}
//
//public protocol Subscription: Cancellable {
//    func onRequestN(_ requestN: Int32)
//}
//
//public protocol UnidirectionalStream: Subscription {
//    func onNext(_ payload: Payload)
//    func onComplete()
//}


public protocol Cancellable {
    func onCancel()
}

public protocol Subscriber {
    func onNext(_ payload: Payload, isComplete: Bool)
    func onError(_ error: Error)
    func onComplete()
}

// alternative:
public protocol _Subscriber {
    func onNext(payload: Payload, isLast: Bool)
    func onTermination(_ error: Error?)
}

// alternative 2:
public protocol Producer {
    func onNext(payload: Payload, isLast: Bool)
}

public protocol Completable {
    func onTermination(_ error: Error?)
}

public protocol Subscription {
    func onRequestN(_ n: Int32)
}

public protocol Extendable {
    func onExtension(
        extendedType: Int32, 
        payload: Payload, 
        canBeIgnored: Bool)
    
}

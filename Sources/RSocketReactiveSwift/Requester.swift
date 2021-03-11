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

import ReactiveSwift
import RSocketCore
import Foundation

internal struct RequesterAdapter: RSocket {
    internal let requester: RSocketCore.RSocket
    
    internal init(requester: RSocketCore.RSocket) {
        self.requester = requester
    }
    
    internal func metadataPush(metadata: Data) {
        requester.metadataPush(metadata: metadata)
    }
    
    internal func fireAndForget(payload: Payload) {
        requester.fireAndForget(payload: payload)
    }

    internal func requestResponse(payload: Payload) -> SignalProducer<Payload, Swift.Error> {
        SignalProducer {[self] (observer, lifetime) in
            let stream = RequestResponseOperator(observer: observer)
            stream.output = requester.requestResponse(payload: payload, responderStream: stream)

            lifetime.observeEnded {
                stream.output?.onCancel()
            }
        }
    }
    internal func requestStream(payload: Payload) -> SignalProducer<Payload, Swift.Error> {
        SignalProducer {[self] (observer, lifetime) in
            let stream = RequestResponseOperator(observer: observer)
            stream.output = requester.stream(payload: payload, initialRequestN: .max, responderStream: stream)

            lifetime.observeEnded {
                stream.output?.onCancel()
            }
        }
    }

    internal func requestChannel(
        payload: Payload,
        isCompleted: Bool,
        payloadProducer: SignalProducer<Payload, Swift.Error>
    ) -> SignalProducer<Payload, Swift.Error> {
        SignalProducer { [self] (observer, lifetime) in
            let stream = RequestResponseOperator(observer: observer)
            let output = requester.channel(payload: payload, initialRequestN: .max, isCompleted: false, responderStream: stream)
            stream.output = output

            lifetime.observeEnded {
                stream.output?.onCancel()
            }
            payloadProducer.start { event in
                switch event {
                case let .value(value):
                    output.onNext(value, isCompletion: false)
                case let .failed(error):
                    output.onError(Error.applicationError(message: error.localizedDescription))
                case .completed:
                    output.onComplete()
                case .interrupted:
                    output.onCancel()
                }
            }
        }
    }
}

extension RSocketCore.RSocket {
    public var reactive: RSocket { RequesterAdapter(requester: self) }
}


fileprivate final class RequestResponseOperator: UnidirectionalStream {
    private let observer: Signal<Payload, Swift.Error>.Observer
    var output: Cancellable?
    internal init(
        observer: Signal<Payload, Swift.Error>.Observer
    ) {
        self.observer = observer
    }
    func onNext(_ payload: Payload, isCompletion: Bool) {
        observer.send(value: payload)
        if isCompletion {
            observer.sendCompleted()
        }
    }
    
    func onError(_ error: Error) {
        observer.send(error: error)
    }
    
    func onComplete() {
        observer.sendCompleted()
    }
    
    func onCancel() {
        observer.sendInterrupted()
    }
    
    func onRequestN(_ requestN: Int32) {
        let error = Error.invalid(message: "\(Self.self) does not support requestN")
        output?.onCancel()
        observer.send(error: error)
    }
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard canBeIgnored == false else { return }
        let error = Error.invalid(message: "\(Self.self) does not support extension type \(extendedType) and it can not be ignored")
        output?.onCancel()
        observer.send(error: error)
    }
}

fileprivate final class RequestStreamOperator: UnidirectionalStream {
    private let observer: Signal<Payload, Swift.Error>.Observer
    var output: Subscription?
    internal init(
        observer: Signal<Payload, Swift.Error>.Observer
    ) {
        self.observer = observer
    }
    func onNext(_ payload: Payload, isCompletion: Bool) {
        observer.send(value: payload)
        if isCompletion {
            observer.sendCompleted()
        }
    }
    
    func onError(_ error: Error) {
        observer.send(error: error)
    }
    
    func onComplete() {
        observer.sendCompleted()
    }
    
    func onCancel() {
        observer.sendInterrupted()
    }
    
    func onRequestN(_ requestN: Int32) {
        let error = Error.invalid(message: "\(Self.self) does not support requestN")
        output?.onCancel()
        observer.send(error: error)
    }
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard canBeIgnored == false else { return }
        let error = Error.invalid(message: "\(Self.self) does not support extension type \(extendedType) and it can not be ignored")
        output?.onCancel()
        observer.send(error: error)
    }
}

fileprivate final class RequestChannelOperator: UnidirectionalStream {
    private let observer: Signal<Payload, Swift.Error>.Observer
    var output: UnidirectionalStream?
    internal init(
        observer: Signal<Payload, Swift.Error>.Observer
    ) {
        self.observer = observer
    }
    func onNext(_ payload: Payload, isCompletion: Bool) {
        observer.send(value: payload)
        if isCompletion {
            observer.sendCompleted()
        }
    }
    
    func onError(_ error: Error) {
        observer.send(error: error)
    }
    
    func onComplete() {
        observer.sendCompleted()
    }
    
    func onCancel() {
        observer.sendInterrupted()
    }
    
    func onRequestN(_ requestN: Int32) {
        /// TODO: ReactiveSwift does not support demand like Combine. What should we do? Ignore it or maybe buffer outgoing data until we are allowed to send it?
    }
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard canBeIgnored == false else { return }
        let error = Error.invalid(message: "\(Self.self) does not support extension type \(extendedType) and it can not be ignored")
        output?.onError(error)
        observer.send(error: error)
    }
}

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

internal class ResponderAdapter: RSocketCore.RSocket {
    private let responder: RSocket
    internal init(responder: RSocket?) {
        self.responder = responder ?? RSocketDefault()
    }
    func metadataPush(metadata: Data) {
        responder.metadataPush(metadata: metadata)
    }
    
    func fireAndForget(payload: Payload) {
        responder.fireAndForget(payload: payload)
    }
    
    func requestResponse(payload: Payload, responderStream: UnidirectionalStream) -> Cancellable {
        ReactiveSwiftRequestResponseResponder(
            producer: responder.requestResponse(payload: payload),
            output: responderStream
        )
    }
    
    func stream(payload: Payload, initialRequestN: Int32, responderStream: UnidirectionalStream) -> Subscription {
        ReactiveSwiftRequestStreamResponder(
            producer: responder.requestStream(payload: payload),
            output: responderStream
        )
    }
    
    func channel(payload: Payload, initialRequestN: Int32, isCompleted: Bool, responderStream: UnidirectionalStream) -> UnidirectionalStream {
        let (signal, observer) = Signal<Payload, Swift.Error>.pipe()
        return ReactiveSwiftRequestChannelResponder(
            observer: observer,
            producer: responder.requestChannel(
                payload: payload,
                isCompleted: isCompleted,
                payloadProducer: SignalProducer({ observer, lifetime in
                    signal.take(during: lifetime).observe(observer)
                })
            ),
            output: responderStream
        )
    }
}

fileprivate extension UnidirectionalStream {
    func send(event: Signal<Payload, Swift.Error>.Event) {
        switch event {
        case let .value(value):
            onNext(value, isCompletion: false)
        case let .failed(error):
            onError(Error.applicationError(message: error.localizedDescription))
        case .completed:
            onComplete()
        case .interrupted:
            onCancel()
        }
    }
}

fileprivate class ReactiveSwiftRequestResponseResponder: Cancellable {
    let disposable: ReactiveSwift.Disposable
    let output: UnidirectionalStream
    
    internal init(producer: SignalProducer<Payload, Swift.Error>, output: UnidirectionalStream) {
        self.output = output
        self.disposable = producer.start { (event) in
            output.send(event: event)
        }
    }
    
    func onCancel() {
        disposable.dispose()
    }
    
    deinit {
        disposable.dispose()
    }
}

fileprivate class ReactiveSwiftRequestStreamResponder: Subscription {
    let disposable: ReactiveSwift.Disposable
    let output: UnidirectionalStream
    
    internal init(producer: SignalProducer<Payload, Swift.Error>, output: UnidirectionalStream) {
        self.output = output
        self.disposable = producer.start { (event) in
            output.send(event: event)
        }
    }
    
    func onCancel() {
        disposable.dispose()
    }
    
    func onRequestN(_ requestN: Int32) {
        // TODO: Not supported by ReactiveSwift. What should we do with it?
    }

    deinit {
        disposable.dispose()
    }
}

fileprivate class ReactiveSwiftRequestChannelResponder: UnidirectionalStream {
    let disposable: ReactiveSwift.Disposable
    let output: UnidirectionalStream
    let observer: Signal<Payload, Swift.Error>.Observer
    
    internal init(
        observer: Signal<Payload, Swift.Error>.Observer,
        producer: SignalProducer<Payload, Swift.Error>,
        output: UnidirectionalStream
    ) {
        self.observer = observer
        self.output = output
        self.disposable = producer.start { (event) in
            output.send(event: event)
        }
    }
    
    func onNext(_ payload: Payload, isCompletion: Bool) {
        observer.send(value: payload)
        if isCompletion {
            observer.sendCompleted()
        }
    }
    
    func onError(_ error: Error) {
        observer.send(error: error)
        // TODO: can we deliver this error to the producer?
        disposable.dispose()
    }
    
    func onComplete() {
        observer.sendCompleted()
    }
    
    func onCancel() {
        observer.sendInterrupted()
    }
    
    func onRequestN(_ requestN: Int32) {
        // TODO: Not supported by ReactiveSwift. What should we do with it?
    }
    
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard !canBeIgnored else { return }
        let error = Error.invalid(message: "\(Self.self) does not support extension type \(extendedType) and it can not be ignored")
        observer.send(error: error)
        output.onError(error)
    }
    deinit {
        disposable.dispose()
    }
}

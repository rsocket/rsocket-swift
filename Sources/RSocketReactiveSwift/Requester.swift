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
@testable import RSocketCore
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
        SignalProducer { observer, lifetime in
            let stream = RequestResponseOperator(observer: observer)
            let output = requester.requestResponse(payload: payload, responderStream: stream)
            lifetime.observeEnded {
                output.onCancel()
            }
        }
    }
    
    internal func requestStream(payload: Payload) -> SignalProducer<Payload, Swift.Error> {
        SignalProducer { observer, lifetime in
            let stream = RequestStreamOperator(observer: observer)
            let output = requester.stream(payload: payload, initialRequestN: .max, responderStream: stream)
            lifetime.observeEnded {
                output.onCancel()
            }
        }
    }
    
    internal func requestChannel(
        payload: Payload,
        payloadProducer: SignalProducer<Payload, Swift.Error>?
    ) -> SignalProducer<Payload, Swift.Error> {
        SignalProducer { observer, lifetime in
            let stream = RequestChannelOperator(observer: observer)
            let isComplete = payloadProducer == nil
            let output = requester.channel(payload: payload, initialRequestN: .max, isCompleted: isComplete, responderStream: stream)
            stream.start(lifetime: lifetime, output: output, payloadProducer: payloadProducer)
        }
    }
}

extension RequesterAdapter {
    func fireAndForget<InputData>(
        _ request: Request<Void, InputData, Never, Never>,
        data: InputData
    ) throws {
        fireAndForget(payload: try request.payload(for: data))
    }
    func requestResponse<InputData, OutputData>(
        _ request: AnyRequest<InputData, OutputData>,
        data: InputData
    ) -> SignalProducer<OutputData, Swift.Error> {
        SignalProducer {
            requestResponse(payload: try request.payload(for: data))
                .attemptMap{ try request.output(from: $0) }
        }.flatten(.latest)
    }
    func requestStream<InputData, OutputData>(
        _ request: AnyRequest<InputData, OutputData>,
        data: InputData
    ) -> SignalProducer<OutputData, Swift.Error> {
        SignalProducer {
            requestStream(payload: try request.payload(for: data))
                .attemptMap{ try request.output(from: $0) }
        }.flatten(.latest)
    }
    func requestChannel<InputData, OutputData>(
        _ request: AnyRequest<InputData, OutputData>,
        data: InputData,
        dataProducer: SignalProducer<InputData, Swift.Error>?
    ) -> SignalProducer<OutputData, Swift.Error> {
        SignalProducer {
            requestChannel(
                payload: try request.payload(for: data),
                payloadProducer: dataProducer?.attemptMap { try request.payload(for: $0) }
            ).attemptMap{ try request.output(from: $0) }
        }.flatten(.latest)
    }
}

fileprivate struct RequestResponseOperator {
    private let observer: Signal<Payload, Swift.Error>.Observer

    internal init(
        observer: Signal<Payload, Swift.Error>.Observer
    ) {
        self.observer = observer
    }
}

extension RequestResponseOperator: UnidirectionalStream {
    func onNext(_ payload: Payload, isCompletion: Bool) {
        observer.send(value: payload)
        observer.sendCompleted()
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
        /// TODO: We need to make the behaviour configurable (e.g. buffering, blocking, dropping, sending) because ReactiveSwift does not support demand.
    }

    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard canBeIgnored == false else { return }
        let error = Error.invalid(message: "\(Self.self) does not support extension type \(extendedType) and it can not be ignored")
        observer.send(error: error)
    }
}

fileprivate struct RequestStreamOperator {
    private let observer: Signal<Payload, Swift.Error>.Observer

    internal init(
        observer: Signal<Payload, Swift.Error>.Observer
    ) {
        self.observer = observer
    }
}

extension RequestStreamOperator: UnidirectionalStream {
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
        /// TODO: We need to make the behaviour configurable (e.g. buffering, blocking, dropping, sending) because ReactiveSwift does not support demand.
    }

    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard canBeIgnored == false else { return }
        let error = Error.invalid(message: "\(Self.self) does not support extension type \(extendedType) and it can not be ignored")
        observer.send(error: error)
    }
}

fileprivate final class RequestChannelOperator {
    private let observer: Signal<Payload, Swift.Error>.Observer
    private var payloadProducerDisposable: Disposable?
    private var isTerminated = false

    internal init(observer: Signal<Payload, Swift.Error>.Observer) {
        self.observer = observer
    }
    
    func start(lifetime: Lifetime, output: UnidirectionalStream, payloadProducer: SignalProducer<Payload, Swift.Error>?) {
        lifetime.observeEnded { [weak self] in
            guard let self = self else { return }
            guard !self.isTerminated else { return }
            output.onCancel()
        }
        payloadProducerDisposable = payloadProducer?.start { event in
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
    
    deinit {
        payloadProducerDisposable?.dispose()
    }
}

extension RequestChannelOperator: UnidirectionalStream {
    func onNext(_ payload: Payload, isCompletion: Bool) {
        observer.send(value: payload)
        if isCompletion {
            isTerminated = true
            observer.sendCompleted()
        }
    }
    
    func onError(_ error: Error) {
        isTerminated = true
        observer.send(error: error)
    }
    
    func onComplete() {
        isTerminated = true
        observer.sendCompleted()
    }
    
    func onCancel() {
        isTerminated = true
        observer.sendInterrupted()
    }
    
    func onRequestN(_ requestN: Int32) {
        /// TODO: We need to make the behaviour configurable (e.g. buffering, blocking, dropping, sending) because ReactiveSwift does not support demand.
    }

    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard canBeIgnored == false else { return }
        let error = Error.invalid(message: "\(Self.self) does not support extension type \(extendedType) and it can not be ignored")
        isTerminated = true
        observer.send(error: error)
    }
}


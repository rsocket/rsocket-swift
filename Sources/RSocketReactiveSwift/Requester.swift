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
import NIOCore

internal struct RequesterAdapter {
    internal let requester: RSocketCore.RSocket
    
    internal init(requester: RSocketCore.RSocket) {
        self.requester = requester
    }
}

extension RequesterAdapter: RequesterRSocket {
    func execute<Metadata>(_ metadataPush: MetadataPush<Metadata>, metadata: Metadata) throws {
        let metadata = try metadataPush.encoder.encode(metadata)
        self.metadataPush(metadata: metadata)
    }

    func execute<Request>(_ fireAndForget: FireAndForget<Request>, request: Request) throws {
        var encoder = fireAndForget.encoder
        let payload = try encoder.encode(request, encoding: encoding)
        self.fireAndForget(payload: payload)
    }

    func build<Request, Response>(
        _ requestResponse: RequestResponse<Request, Response>,
        request: Request
    ) -> SignalProducer<Response, Swift.Error> {
        SignalProducer { () throws -> SignalProducer<Response, Swift.Error> in
            var encoder = requestResponse.encoder
            var decoder = requestResponse.decoder
            let payload = try encoder.encode(request, encoding: encoding)
            return self.requestResponse(payload: payload).attemptMap { response in
                try decoder.decode(response, encoding: encoding)
            }
        }.flatten(.latest)
    }

    func build<Request, Response>(
        _ requestStream: RequestStream<Request, Response>,
        request: Request
    ) -> SignalProducer<Response, Swift.Error> {
        SignalProducer { () throws -> SignalProducer<Response, Swift.Error> in
            var encoder = requestStream.encoder
            var decoder = requestStream.decoder
            let payload = try encoder.encode(request, encoding: encoding)
            return self.requestStream(payload: payload).attemptMap { response in
                try decoder.decode(response, encoding: encoding)
            }
        }.flatten(.latest)
    }

    func build<Request, Response>(
        _ requestChannel: RequestChannel<Request, Response>,
        initialRequest: Request,
        producer: SignalProducer<Request, Swift.Error>?
    ) -> SignalProducer<Response, Swift.Error> {
        SignalProducer { () throws -> SignalProducer<Response, Swift.Error> in
            var encoder = requestChannel.encoder
            var decoder = requestChannel.decoder
            let payload = try encoder.encode(initialRequest, encoding: encoding)
            let payloadProducer = producer?.attemptMap { data in
                try encoder.encode(data, encoding: encoding)
            }
            return self.requestChannel(payload: payload, payloadProducer: payloadProducer).attemptMap{ response in
                try decoder.decode(response, encoding: encoding)
            }
        }.flatten(.latest)
    }
}


extension RequesterAdapter {
    internal var encoding: ConnectionEncoding {
        requester.encoding
    }
    
    internal func metadataPush(metadata: ByteBuffer) {
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


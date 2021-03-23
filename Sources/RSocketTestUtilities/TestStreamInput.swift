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
import XCTest

public final class TestStreamInput {
    public enum Event: Hashable {
        case next(Payload, isCompletion: Bool)
        case error(Error)
        case complete
        case cancel
        case requestN(Int32)
        case `extension`(extendedType: Int32, payload: Payload, canBeIgnored: Bool)
    }
    public private(set) var events: [Event] = []
    public var failOnUnexpectedEvent: Bool
    public var onNextCallback: ((_ payload: Payload, _ isCompletion: Bool) -> ())?
    public var onErrorCallback: ((_ error: Error) -> ())?
    public var onCompleteCallback: (() -> ())?
    public var onCancelCallback: (() -> ())?
    public var onRequestNCallback: ((_ requestN: Int32) -> ())?
    public var onExtensionCallback: ((_ extendedType: Int32, _ payload: Payload, _ canBeIgnored: Bool) -> ())?
    private let file: StaticString
    private let line: UInt
    
    public init(
        onNext: ((Payload, Bool) -> ())? = nil,
        onError: ((Error) -> ())? = nil,
        onComplete: (() -> ())? = nil,
        onCancel: (() -> ())? = nil,
        onRequestN: ((Int32) -> ())? = nil,
        onExtension: ((Int32, Payload, Bool) -> ())? = nil,
        failOnUnexpectedEvent: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.onNextCallback = onNext
        self.onErrorCallback = onError
        self.onCompleteCallback = onComplete
        self.onCancelCallback = onCancel
        self.onRequestNCallback = onRequestN
        self.onExtensionCallback = onExtension
        self.failOnUnexpectedEvent = failOnUnexpectedEvent
        self.file = file
        self.line = line
    }
    
    private func didReceiveEvent<Callback>(_ event: Event, callback: Callback?, notify: (Callback) -> ()) {
        events.append(event)
        notifyCallbackOrFailIfNeeded(event: event, callback: callback, notify: notify)
    }
    private func notifyCallbackOrFailIfNeeded<Callback>(event: Event, callback: Callback?, notify: (Callback) -> ()) {
        guard let callback = callback else {
            eventWithoutCallback(event: event)
            return
        }
        notify(callback)
    }
    private func eventWithoutCallback(event: Event) {
        if failOnUnexpectedEvent {
            XCTFail("did receive unexpected event \(event)")
        }
    }
}

extension TestStreamInput: UnidirectionalStream {
    public func onNext(_ payload: Payload, isCompletion: Bool) {
        didReceiveEvent(.next(payload, isCompletion: isCompletion), callback: onNextCallback) {
            $0(payload, isCompletion)
        }
    }
    public func onError(_ error: Error) {
        didReceiveEvent(.error(error), callback: onErrorCallback) {
            $0(error)
        }
    }
    public func onComplete() {
        didReceiveEvent(.complete, callback: onCompleteCallback) {
            $0()
        }
    }
    public func onCancel() {
        didReceiveEvent(.cancel, callback: onCancelCallback) {
            $0()
        }
    }
    public func onRequestN(_ requestN: Int32) {
        didReceiveEvent(.requestN(requestN), callback: onRequestNCallback) {
            $0(requestN)
        }
    }
    public func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        didReceiveEvent(
            .extension(extendedType: extendedType, payload: payload, canBeIgnored: canBeIgnored),
            callback: onExtensionCallback
        ) {
            $0(extendedType, payload, canBeIgnored)
        }
    }
}

extension TestStreamInput {
    public static func echo(to output: UnidirectionalStream) -> TestStreamInput {
        return TestStreamInput {
            output.onNext($0, isCompletion: $1)
        } onError: {
            output.onError($0)
        } onComplete: {
            output.onComplete()
        } onCancel: {
            output.onCancel()
        } onRequestN: {
            output.onRequestN($0)
        } onExtension: {
            output.onExtension(extendedType: $0, payload: $1, canBeIgnored: $2)
        }
    }
}

extension TestStreamInput.Event: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .next(.init(stringLiteral: value), isCompletion: false)
    }
}

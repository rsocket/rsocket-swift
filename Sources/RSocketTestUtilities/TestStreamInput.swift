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

public final class TestStreamInput: RSocketCore.UnidirectionalStream {
    public enum Event: Hashable {
        case next(Payload, isCompletion: Bool)
        case error(Error)
        case complete
        case cancel
        case requestN(Int32)
        case `extension`(extendedType: Int32, payload: Payload, canBeIgnored: Bool)
    }
    public private(set) var events: [Event] = []
    public var onNextCallback: (_ payload: Payload, _ isCompletion: Bool) -> ()
    public var onErrorCallback: (_ error: Error) -> ()
    public var onCompleteCallback: () -> ()
    public var onCancelCallback: () -> ()
    public var onRequestNCallback: (_ requestN: Int32) -> ()
    public var onExtensionCallback: (_ extendedType: Int32, _ payload: Payload, _ canBeIgnored: Bool) -> ()
    public var onCompletionOrOnNextWithIsCompletionTrue: () -> ()
    
    public init(
        onNext: @escaping (Payload, Bool) -> () = { _,_ in },
        onError: @escaping (Error) -> () = { _ in },
        onComplete: @escaping () -> () = {},
        onCancel: @escaping () -> () = {},
        onRequestN: @escaping (Int32) -> () = { _ in },
        onExtension: @escaping (Int32, Payload, Bool) -> () = { _,_,_ in },
        onCompletionOrOnNextWithIsCompletionTrue: @escaping () -> () = {}
    ) {
        self.onNextCallback = onNext
        self.onErrorCallback = onError
        self.onCompleteCallback = onComplete
        self.onCancelCallback = onCancel
        self.onRequestNCallback = onRequestN
        self.onExtensionCallback = onExtension
        self.onCompletionOrOnNextWithIsCompletionTrue = onCompletionOrOnNextWithIsCompletionTrue
    }
    
    public func onNext(_ payload: Payload, isCompletion: Bool) {
        events.append(.next(payload, isCompletion: isCompletion))
        onNextCallback(payload, isCompletion)
        if isCompletion {
            onCompletionOrOnNextWithIsCompletionTrue()
        }
    }
    public func onError(_ error: Error) {
        events.append(.error(error))
        onErrorCallback(error)
    }
    public func onComplete() {
        events.append(.complete)
        onCompleteCallback()
        onCompletionOrOnNextWithIsCompletionTrue()
    }
    public func onCancel() {
        events.append(.cancel)
        onCancelCallback()
    }
    public func onRequestN(_ requestN: Int32) {
        events.append(.requestN(requestN))
        onRequestNCallback(requestN)
    }
    public func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        events.append(.extension(extendedType: extendedType, payload: payload, canBeIgnored: canBeIgnored))
        onExtensionCallback(extendedType, payload, canBeIgnored)
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

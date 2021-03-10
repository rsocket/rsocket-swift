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

extension Cancellable {
    internal func receive(_ frame: Frame) -> Error? {
        switch frame.body {
        case .cancel:
            onCancel()
        default:
            if !frame.header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(frame.body.type) for an active cancelable")
            }
        }
        return nil
    }
}
extension Subscription {
    internal func receive(_ frame: Frame) -> Error? {
        switch frame.body {
        case let .requestN(body):
            onRequestN(body.requestN)
        case .cancel:
            onCancel()
        default:
            if !frame.header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(frame.body.type) for an active subscription")
            }
        }
        return nil
    }
}
extension UnidirectionalStream {
    internal func receive(_ frame: Frame) -> Error? {
        switch frame.body {
        case let .requestN(body):
            onRequestN(body.requestN)

        case .cancel:
            onCancel()

        case let .payload(body):
            if body.isNext {
                onNext(body.payload, isCompletion: body.isCompletion)
            } else if body.isCompletion {
                onComplete()
            }

        case let .error(body):
            onError(body.error)

        case let .ext(body):
            onExtension(
                extendedType: body.extendedType,
                payload: body.payload,
                canBeIgnored: body.canBeIgnored
            )
        default:
            if !frame.header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(frame.body.type) for an active unidirectional stream")
            }
        }
        return nil
    }
}

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


extension Frame {
    internal func forward(to stream: Cancellable) -> Error? {
        switch body {
        case .cancel:
            stream.onCancel()
        default:
            if !header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(self.body.type) for an active cancelable")
            }
        }
        return nil
    }
    func forward(to stream: Subscription) -> Error? {
        switch body {
        case let .requestN(body):
            stream.onRequestN(body.requestN)
        case .cancel:
            stream.onCancel()
        default:
            if !header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(self.body.type) for an active subscription")
            }
        }
        return nil
    }
    func forward(to stream: UnidirectionalStream) -> Error? {
        switch body {
        case let .requestN(body):
            stream.onRequestN(body.requestN)

        case .cancel:
            stream.onCancel()

        case let .payload(body):
            if body.isNext {
                stream.onNext(body.payload, isCompletion: body.isCompletion)
            } else if body.isCompletion {
                stream.onComplete()
            }

        case let .error(body):
            stream.onError(body.error)

        case let .ext(body):
            stream.onExtension(
                extendedType: body.extendedType,
                payload: body.payload,
                canBeIgnored: body.canBeIgnored
            )
        default:
            if !header.flags.contains(.ignore) {
                return .connectionError(message: "Invalid frame type \(self.body.type) for an active unidirectional stream")
            }
        }
        return nil
    }
}

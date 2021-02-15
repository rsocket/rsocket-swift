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

public protocol StreamInput {
    func onNext(_ payload: Payload)
    func onError(_ error: Error)
    func onComplete()
    func onCancel()
    func onRequestN(_ requestN: Int32)
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool)
}

extension StreamInput {
    func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) { }
}

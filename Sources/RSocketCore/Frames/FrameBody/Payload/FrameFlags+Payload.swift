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

extension FrameFlags {
    /// (F)ollows: More fragments follow this fragment
    internal static let payloadFollows = FrameFlags(rawValue: 1 << 7)

    /**
     (C)omplete: bit to indicate stream completion

     If set, `onComplete()` or equivalent will be invoked on Subscriber/Observer.
     */
    internal static let payloadComplete = FrameFlags(rawValue: 1 << 6)

    /**
     (N)ext: bit to indicate Next (Payload Data and/or Metadata present)

     If set, `onNext(Payload)` or equivalent will be invoked on Subscriber/Observer.
     */
    internal static let payloadNext = FrameFlags(rawValue: 1 << 5)
}

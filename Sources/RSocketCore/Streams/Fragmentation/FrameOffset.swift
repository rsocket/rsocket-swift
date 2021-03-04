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

internal enum FrameOffset {
    case requestResponse
    case requestFnf
    case requestStream
    case requestChannel
    case payload

    internal var numberOfBytes: Int {
        switch self {
        case .payload, .requestResponse, .requestFnf:
            return 0
        case .requestStream, .requestChannel:
            return 4
        }
    }
}

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

internal struct StreamIDGenerator {
    private var nextStreamId: StreamID.RawValue
    internal init(initial: StreamID.RawValue) {
        self.nextStreamId = initial
    }
    mutating func next() -> StreamID? {
        guard nextStreamId > 0 else { return nil }
        defer { nextStreamId &+= 2 }
        return StreamID(rawValue: nextStreamId)
    }
}

extension StreamIDGenerator {
    static let client = StreamIDGenerator(initial: 1)
    static let server = StreamIDGenerator(initial: 2)
}

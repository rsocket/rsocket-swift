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

internal struct FrameHeader: Hashable {
    internal static let lengthInBytes = 6

    /// The id of the corresponding stream
    internal var streamId: StreamID

    /// The type of the frame
    internal var type: FrameType

    /// The flags that are set on the frame
    internal var flags: FrameFlags
}

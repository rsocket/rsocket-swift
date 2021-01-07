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

import Foundation

/// A cancel frame indicates the cancellation of an outstanding request
internal struct CancelFrame {
    /// The header of this frame
    internal let header: FrameHeader

    internal init(header: FrameHeader) {
        self.header = header
    }

    internal init(streamId: Int32) {
        self.header = FrameHeader(streamId: streamId, type: .cancel, flags: [])
    }
}

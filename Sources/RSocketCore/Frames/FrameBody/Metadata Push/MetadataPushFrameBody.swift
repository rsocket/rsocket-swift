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

/// A Metadata Push frame can be used to send asynchronous metadata notifications from a Requester or Responder to its peer
internal struct MetadataPushFrameBody: Hashable {
    /// Metadata of this frame
    internal var metadata: ByteBuffer
}

extension MetadataPushFrameBody: FrameBodyBoundToConnection {
    func body() -> FrameBody { .metadataPush(self) }
    func header() -> FrameHeader {
        return FrameHeader(streamId: .connection, type: .metadataPush, flags: .metadata)
    }
}

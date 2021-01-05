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

/// Request a completable stream in both directions
public struct RequestChannelFrame {
    /// The header of this frame
    public let header: FrameHeader

    /**
     The initial number of items to request

     Value MUST be > `0`.
     */
    public let initialRequestN: Int32

    /// Optional metadata of this frame
    public let metadata: Data?

    /// Identification of the service being requested along with parameters for the request
    public let payload: Data

    public init(
        header: FrameHeader,
        initialRequestN: Int32,
        metadata: Data?,
        payload: Data
    ) {
        self.header = header
        self.initialRequestN = initialRequestN
        self.metadata = metadata
        self.payload = payload
    }
}

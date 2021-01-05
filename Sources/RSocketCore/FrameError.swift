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

public enum FrameError: Error {
    /// The given data is too small and can not be parsed
    case tooSmall

    /// The given string contains invalid characters which can not be represented in the required encoding
    case stringContainsInvalidCharacters

    /// The metadata is too big and can't be encoded
    case metadataTooBig

    /// An error occurred while reading/writing the frame header
    case header(FrameHeaderError)

    /// An error occurred while reading/writing the `SETUP` frame
    case setup(SetupFrameError)

    /// An error occurred while reading/writing the `ERROR` frame
    case error(ErrorFrameError)

    /// An error occurred while reading/writing the `LEASE` frame
    case lease(LeaseFrameError)

    /// An error occurred while reading/writing the `KEEPALIVE` frame
    case keepAlive(KeepAliveFrameError)

    /// An error occurred while reading/writing the `REQUEST_STREAM` frame
    case requestStream(RequestStreamFrameError)

    /// An error occurred while reading/writing the `REQUEST_CHANNEL` frame
    case requestChannel(RequestChannelFrameError)

    /// An error occurred while reading/writing the `REQUEST_N` frame
    case requestN(RequestNFrameError)

    /// An error occurred while reading/writing the `METADATA_PUSH` frame
    case metadataPush(MetadataPushFrameError)

    /// An error occurred while reading/writing the `EXT` frame
    case `extension`(ExtensionFrameError)

    /// An error occurred while reading/writing the `RESUME` frame
    case resume(ResumeFrameError)

    /// An error occurred while reading/writing the `RESUME_OK` frame
    case resumeOk(ResumeOkFrameError)
}

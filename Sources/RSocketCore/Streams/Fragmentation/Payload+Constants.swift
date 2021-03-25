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

extension Payload {
    internal enum Constants {
        static let minMtuSize: Int32 = 64
        static let metadataLength: Int32 = 3
        static let frameHeaderOffset: Int32 = Int32(FrameHeader.lengthInBytes)
        static let frameHeaderOffsetWithMetadata: Int32 = frameHeaderOffset + metadataLength
    }
}

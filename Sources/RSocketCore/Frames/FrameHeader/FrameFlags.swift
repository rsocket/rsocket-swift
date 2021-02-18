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

internal struct FrameFlags: OptionSet, Hashable {
    internal let rawValue: UInt16

    /**
     (I)gnore: Ignore frame if not understood

     The (I)gnore flag is used for extension of the protocol.
     A value of 0 in a frame for this flag indicates the protocol can't ignore this frame.
     An implementation MAY send an ERROR[CONNECTION_ERROR] frame and close the underlying transport
     connection on reception of a frame that it does not understand with this bit not set.
     */
    internal static let ignore = FrameFlags(rawValue: 1 << 9)

    /// (M)etadata: Indicates that the frame contains metadata
    internal static let metadata = FrameFlags(rawValue: 1 << 8)
}

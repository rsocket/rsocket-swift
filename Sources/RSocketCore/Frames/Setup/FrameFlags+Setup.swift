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

extension FrameFlags {
    /**
     (R)esume Enable: Client requests resume capability if possible
     
     Resume Identification Token present.
     */
    public static let setupResume = FrameFlags(rawValue: 1 << 7)

    /// (L)ease: Will honor `LEASE` (or not)
    public static let setupLease = FrameFlags(rawValue: 1 << 6)
}

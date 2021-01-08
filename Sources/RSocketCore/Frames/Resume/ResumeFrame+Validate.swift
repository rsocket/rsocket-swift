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

extension ResumeFrame {
    internal func validate() throws {
        guard lastReceivedServerPosition >= 0 else {
            throw Error.connectionError(message: "lastReceivedServerPosition has to be equal or bigger than 0")
        }
        guard firstAvailableClientPosition >= 0 else {
            throw Error.connectionError(message: "firstAvailableClientPosition has to be equal or bigger than 0")
        }
    }
}

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

extension ErrorFrame {
    internal func validate() throws {
        if header.streamId == 0 {
            switch error {
            case .invalidSetup, .unsupportedSetup, .rejectedSetup, .connectionError, .connectionClose:
                break

            default:
                throw Error.connectionError(message: "The given error code is not valid for this streamId")
            }
        } else {
            switch error {
            case .applicationError, .rejected, .canceled, .invalid:
                break

            case .other where error.isApplicationLayerError:
                break

            default:
                throw Error.connectionError(message: "The given error code is not valid for this streamId")
            }
        }
    }
}

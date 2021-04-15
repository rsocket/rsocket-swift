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

extension Frame {
    internal func validate() throws {
        guard header.streamId.rawValue >= 0 else {
            throw Error.connectionError(message: "streamId has to be equal or bigger than 0")
        }
        switch body {
        case let .error(body):
            if header.streamId == .connection {
                switch body.error.code {
                case .invalidSetup, .unsupportedSetup, .rejectedSetup, .connectionError, .connectionClose:
                    break

                default:
                    throw Error.connectionError(message: "The given error code is not valid for this streamId")
                }
            } else {
                switch body.error.code {
                case .applicationError, .rejected, .canceled, .invalid:
                    break

                case _ where body.error.code.isApplicationLayerError:
                    break

                default:
                    throw Error.connectionError(message: "The given error code is not valid for this streamId")
                }
            }

        case let .ext(body):
            guard body.extendedType >= 0 else {
                throw Error.connectionError(message: "extendedType has to be equal or bigger than 0")
            }

        case let .keepalive(body):
            guard header.streamId == .connection else {
                throw Error.connectionError(message: "streamId has to be 0")
            }
            guard body.lastReceivedPosition >= 0 else {
                throw Error.connectionError(message: "lastReceivedPosition has to be equal or bigger than 0")
            }

        case let .lease(body):
            guard header.streamId == .connection else {
                throw Error.connectionError(message: "streamId has to be 0")
            }
            guard body.timeToLive >= 0 else {
                throw Error.connectionError(message: "timeToLive has to be equal or bigger than 0")
            }
            guard body.numberOfRequests >= 0 else {
                throw Error.connectionError(message: "numberOfRequests has to be equal or bigger than 0")
            }

        case .metadataPush:
            guard header.streamId == .connection else {
                throw Error.connectionError(message: "streamId has to be 0")
            }

        case let .requestChannel(body):
            guard body.initialRequestN > 0 else {
                throw Error.connectionError(message: "initialRequestN has to be bigger than 0")
            }

        case let .requestN(body):
            guard body.requestN > 0 else {
                throw Error.connectionError(message: "requestN has to be bigger than 0")
            }

        case let .requestStream(body):
            guard body.initialRequestN > 0 else {
                throw Error.connectionError(message: "initialRequestN has to be bigger than 0")
            }

        case let .resume(body):
            guard body.lastReceivedServerPosition >= 0 else {
                throw Error.connectionError(message: "lastReceivedServerPosition has to be equal or bigger than 0")
            }
            guard body.firstAvailableClientPosition >= 0 else {
                throw Error.connectionError(message: "firstAvailableClientPosition has to be equal or bigger than 0")
            }

        case let .resumeOk(body):
            guard body.lastReceivedClientPosition >= 0 else {
                throw Error.connectionError(message: "lastReceivedClientPosition has to be equal or bigger than 0")
            }

        case let .setup(body):
            guard header.streamId == .connection else {
                throw Error.connectionError(message: "streamId has to be 0")
            }
            guard body.timeBetweenKeepaliveFrames > 0 else {
                throw Error.connectionError(message: "timeBetweenKeepaliveFrames has to be bigger than 0")
            }
            guard body.maxLifetime > 0 else {
                throw Error.connectionError(message: "maxLifetime has to be bigger than 0")
            }

        default: break
        }
    }
}

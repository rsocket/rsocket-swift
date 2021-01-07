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

public enum ErrorCode {
    /// Reserved
    case reservedLower

    /**
     The Setup frame is invalid for the server (it could be that the client is too recent for the old server)

     Stream ID MUST be `0`.
     */
    case invalidSetup

    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    case unsupportedSetup

    /**
     The server rejected the setup, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    case rejectedSetup

    /**
     The server rejected the resume, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    case rejectedResume

    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MAY close the connection immediately without waiting for outstanding streams to terminate.
     */
    case connectionError

    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MUST wait for outstanding streams to terminate before closing the connection. New requests MAY not be accepted.
     */
    case connectionClose

    /**
     Application layer logic generating a Reactive Streams `onError` event

     Stream ID MUST be > `0`.
     */
    case applicationError

    /**
     Despite being a valid request, the Responder decided to reject it

     Stream ID MUST be > `0`. The Responder guarantees that it didn't process the request. The reason for the rejection is explained in the Error Data section.
     */
    case rejected

    /**
     The Responder canceled the request but may have started processing it (similar to `REJECTED` but doesn't guarantee lack of side-effects)

     Stream ID MUST be > `0`.
     */
    case canceled

    /**
     The request is invalid

     Stream ID MUST be > `0`.
     */
    case invalid

    /// Reserved for Extension Use
    case reservedUpper

    /// Error code not listed in this enumeration.
    case other(UInt32)
}

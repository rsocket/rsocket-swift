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

/**
 Errors are used on individual requests/streams as well
 as connection errors and in response to `SETUP` frames.
 */
public enum Error: Swift.Error, Hashable {
    enum Kind {
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
         Some (or all) of the parameters specified by the client are unsupported by the server

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
        case other
    }
    /// Reserved
    case reservedLower(message: String)

    /**
     The Setup frame is invalid for the server (it could be that the client is too recent for the old server)

     Stream ID MUST be `0`.
     */
    case invalidSetup(message: String)

    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    case unsupportedSetup(message: String)

    /**
     The server rejected the setup, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    case rejectedSetup(message: String)

    /**
     The server rejected the resume, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    case rejectedResume(message: String)

    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MAY close the connection immediately without waiting for outstanding streams to terminate.
     */
    case connectionError(message: String)

    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MUST wait for outstanding streams to terminate before closing the connection. New requests MAY not be accepted.
     */
    case connectionClose(message: String)

    /**
     Application layer logic generating a Reactive Streams `onError` event

     Stream ID MUST be > `0`.
     */
    case applicationError(message: String)

    /**
     Despite being a valid request, the Responder decided to reject it

     Stream ID MUST be > `0`. The Responder guarantees that it didn't process the request. The reason for the rejection is explained in the Error Data section.
     */
    case rejected(message: String)

    /**
     The Responder canceled the request but may have started processing it (similar to `REJECTED` but doesn't guarantee lack of side-effects)

     Stream ID MUST be > `0`.
     */
    case canceled(message: String)

    /**
     The request is invalid

     Stream ID MUST be > `0`.
     */
    case invalid(message: String)

    /// Reserved for Extension Use
    case reservedUpper(message: String)

    /// Error code not listed in this enumeration.
    case other(code: UInt32, message: String)
}

extension Error {
    var kind: Kind {
        switch self {
        case .reservedLower: return .reservedLower
        case .invalidSetup: return .invalidSetup
        case .unsupportedSetup: return .unsupportedSetup
        case .rejectedSetup: return .rejectedSetup
        case .rejectedResume: return .rejectedResume
        case .connectionError: return .connectionError
        case .connectionClose: return .connectionClose
        case .applicationError: return .applicationError
        case .rejected: return .rejected
        case .canceled: return .canceled
        case .invalid: return .invalid
        case .reservedUpper: return .reservedUpper
        case .other: return .other
        }
    }
    public var code: UInt32 {
        switch self {
        case .reservedLower:
            return 0x00000000

        case .invalidSetup:
            return 0x00000001

        case .unsupportedSetup:
            return 0x00000002

        case .rejectedSetup:
            return 0x00000003

        case .rejectedResume:
            return 0x00000004

        case .connectionError:
            return 0x00000101

        case .connectionClose:
            return 0x00000102

        case .applicationError:
            return 0x00000201

        case .rejected:
            return 0x00000202

        case .canceled:
            return 0x00000203

        case .invalid:
            return 0x00000204

        case .reservedUpper:
            return 0xFFFFFFFF

        case let .other(code: code, message: _):
            return code
        }
    }

    public var message: String {
        switch self {
        case let .reservedLower(message: message),
             let .invalidSetup(message: message),
             let .unsupportedSetup(message: message),
             let .rejectedSetup(message: message),
             let .rejectedResume(message: message),
             let .connectionError(message: message),
             let .connectionClose(message: message),
             let .applicationError(message: message),
             let .rejected(message: message),
             let .canceled(message: message),
             let .invalid(message: message),
             let .reservedUpper(message: message),
             let .other(code: _, message: message):
            return message
        }
    }
    public var isConnectionError: Bool {
        switch self {
        case .invalidSetup,
             .unsupportedSetup,
             .rejectedSetup,
             .rejectedResume,
             .connectionError,
             .connectionClose:
            return true
        case .reservedLower,
             .applicationError,
             .rejected,
             .canceled,
             .invalid,
             .reservedUpper,
             .other:
            return false
        }
    }
    public var isProtocolError: Bool {
        0x0001 <= code && code <= 0x00300
    }

    public var isApplicationLayerError: Bool {
        0x00301 <= code && code <= 0xFFFFFFFE
    }

    public init(code: UInt32, message: String) {
        switch code {
        case 0x00000000:
            self = .reservedLower(message: message)

        case 0x00000001:
            self = .invalidSetup(message: message)

        case 0x00000002:
            self = .unsupportedSetup(message: message)

        case 0x00000003:
            self = .rejectedSetup(message: message)

        case 0x00000004:
            self = .rejectedResume(message: message)

        case 0x00000101:
            self = .connectionError(message: message)

        case 0x00000102:
            self = .connectionClose(message: message)

        case 0x00000201:
            self = .applicationError(message: message)

        case 0x00000202:
            self = .rejected(message: message)

        case 0x00000203:
            self = .canceled(message: message)

        case 0x00000204:
            self = .invalid(message: message)

        case 0xFFFFFFFF:
            self = .reservedUpper(message: message)

        default:
            self = .other(code: code, message: message)
        }
    }
}

extension Error {
    /// Creates an error frame from `self`. Depending on the error type, it uses the given `streamId` or the connection stream id (stream 0).
    ///
    /// This allows the call side to create error frames without knowing whether the error should be sent on the connection or on the specified stream.
    /// It is especially useful in case the error is later changed from an error that should be sent on the stream instead of on the connection.
    /// Then the call side would not need to be change, thus can not be forgotten.
    /// - Parameter streamId: used if it is *not* a connection error
    /// - Returns: Error Frame
    internal func asFrame(withStreamId streamId: StreamID) -> Frame {
        ErrorFrameBody(error: self)
            .asFrame(withStreamId: isConnectionError ? .connection : streamId)
    }
}

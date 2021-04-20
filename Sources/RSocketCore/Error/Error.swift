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


public struct Error: Swift.Error, Hashable {
    public struct Code: RawRepresentable, Hashable {
        
        public var rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }
    
    public var code: Code
    
    public var message: String
    
    public init(code: Error.Code, message: String) {
        self.code = code
        self.message = message
    }
}

extension Error.Code {
    public var isConnectionError: Bool {
        switch self {
        case .invalidSetup,
             .unsupportedSetup,
             .rejectedSetup,
             .rejectedResume,
             .connectionError,
             .connectionClose:
            return true
        default: return false
        }
    }
    public var isProtocolError: Bool {
        (0x0001...0x00300).contains(rawValue)
    }

    public var isApplicationLayerError: Bool {
        (0x00301...0xFFFFFFFE).contains(rawValue)
    }
}

/// Error codes defined by RSocket
extension Error.Code {
    /// Reserved
    static let reservedLower = Self(rawValue: 0x00000000)
    
    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    static let invalidSetup = Self(rawValue: 0x00000001)
    
    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    static let unsupportedSetup = Self(rawValue: 0x00000002)
    
    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    static let rejectedSetup = Self(rawValue: 0x00000003)
    
    /**
     The server rejected the resume, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    static let rejectedResume = Self(rawValue: 0x00000004)
    
    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MAY close the connection immediately without waiting for outstanding streams to terminate.
     */
    static let connectionError = Self(rawValue: 0x00000101)
    
    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MUST wait for outstanding streams to terminate before closing the connection. New requests MAY not be accepted.
     */
    static let connectionClose = Self(rawValue: 0x00000102)
    
    /**
     Application layer logic generating a Reactive Streams `onError` event

     Stream ID MUST be > `0`.
     */
    public static let applicationError = Self(rawValue: 0x00000201)
    
    /**
     Despite being a valid request, the Responder decided to reject it

     Stream ID MUST be > `0`. The Responder guarantees that it didn't process the request. The reason for the rejection is explained in the Error Data section.
     */
    public static let rejected = Self(rawValue: 0x00000202)
    
    /**
     The Responder canceled the request but may have started processing it (similar to `REJECTED` but doesn't guarantee lack of side-effects)

     Stream ID MUST be > `0`.
     */
    public static let canceled = Self(rawValue: 0x00000203)
    
    /**
     The request is invalid

     Stream ID MUST be > `0`.
     */
    public static let invalid = Self(rawValue: 0x00000204)
    
    /// Reserved for Extension Use
    static let reservedUpper = Self(rawValue: 0xFFFFFFFF)
}

extension Error.Code: CustomStringConvertible {
    private var name: String? {
        switch self {
        case .reservedLower: return "reservedLower"
        case .invalidSetup: return "invalidSetup"
        case .unsupportedSetup: return "unsupportedSetup"
        case .rejectedSetup: return "rejectedSetup"
        case .rejectedResume: return "rejectedResume"
        case .connectionError: return "connectionError"
        case .connectionClose: return "connectionClose"
        case .applicationError: return "applicationError"
        case .rejected: return "rejected"
        case .canceled: return "canceled"
        case .invalid: return "invalid"
        case .reservedUpper: return "reservedUpper"
        default: return nil
        }
    }
    public var description: String {
        guard let name = name else {
            return "customError(code: \(rawValue))"
        }
        return name
    }
}

/// - MARK: Convenience Initialiser
extension Error {
    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    static func invalidSetup(message: String) -> Self {
        .init(code: .invalidSetup, message: message)
    }
    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    static func unsupportedSetup(message: String) -> Self {
        .init(code: .unsupportedSetup, message: message)
    }
    /**
     Some (or all) of the parameters specified by the client are unsupported by the server

     Stream ID MUST be `0`.
     */
    static func rejectedSetup(message: String) -> Self {
        .init(code: .rejectedSetup, message: message)
    }
    /**
     The server rejected the resume, it can specify the reason in the payload

     Stream ID MUST be `0`.
     */
    static func rejectedResume(message: String) -> Self {
        .init(code: .rejectedResume, message: message)
    }
    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MAY close the connection immediately without waiting for outstanding streams to terminate.
     */
    static func connectionError(message: String) -> Self {
        .init(code: .connectionError, message: message)
    }
    /**
     The connection is being terminated

     Stream ID MUST be `0`. Sender or Receiver of this frame MUST wait for outstanding streams to terminate before closing the connection. New requests MAY not be accepted.
     */
    static func connectionClose(message: String) -> Self {
        .init(code: .connectionClose, message: message)
    }
    /**
     Application layer logic generating a Reactive Streams `onError` event

     Stream ID MUST be > `0`.
     */
    public static func applicationError(message: String) -> Self {
        .init(code: .applicationError, message: message)
    }
    /**
     Despite being a valid request, the Responder decided to reject it

     Stream ID MUST be > `0`. The Responder guarantees that it didn't process the request. The reason for the rejection is explained in the Error Data section.
     */
    public static func rejected(message: String) -> Self {
        .init(code: .rejected, message: message)
    }
    /**
     The Responder canceled the request but may have started processing it (similar to `REJECTED` but doesn't guarantee lack of side-effects)

     Stream ID MUST be > `0`.
     */
    public static func canceled(message: String) -> Self {
        .init(code: .canceled, message: message)
    }
    /**
     The request is invalid

     Stream ID MUST be > `0`.
     */
    public static func invalid(message: String) -> Self {
        .init(code: .invalid, message: message)
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
            .asFrame(withStreamId: code.isConnectionError ? .connection : streamId)
    }
}

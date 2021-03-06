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

internal enum TerminationEvent {
    case cancel
    case error
    case complete
}

internal protocol TerminationBehaviour {
    /// - Parameter event: true if the stream should be terminated
    mutating func shouldTerminateAfterRequesterSent(event: TerminationEvent) -> Bool
    /// - Parameter event: true if the stream should be terminated
    mutating func shouldTerminateAfterResponderSent(event: TerminationEvent) -> Bool
}

/// Implements the termination behaviour of fire & forget.
/// - Note:
///     returns true if one of the following conditions is met:
///     - Requester sends cancel frame or
///     - Responder sends cancel frame, error frame or payload with complete flag set
internal struct RequestResponseTerminationBehaviour: TerminationBehaviour  {
    mutating func shouldTerminateAfterRequesterSent(event: TerminationEvent) -> Bool {
        switch event {
        case .cancel: return true
        case .complete, .error: return false
        }
    }
    mutating func shouldTerminateAfterResponderSent(event: TerminationEvent) -> Bool {
        switch event {
        case .cancel, .complete, .error: return true
        }
    }
}

/// Implements the termination behaviour of stream.
/// - Note:
///     returns true if one of the following conditions is met:
///     - Requester sends cancel frame or
///     - Responder sends cancel frame, error frame or payload with complete flag set
internal struct StreamTerminationBehaviour: TerminationBehaviour {
    mutating func shouldTerminateAfterRequesterSent(event: TerminationEvent) -> Bool {
        switch event {
        case .cancel: return true
        case .complete, .error: return false
        }
    }
    mutating func shouldTerminateAfterResponderSent(event: TerminationEvent) -> Bool {
        switch event {
        case .cancel, .complete, .error: return true
        }
    }
}

/// Implements the termination behaviour of channel.
/// - Note:
///     returns true if one of the following conditions is met:
///     - Requester sends cancel frame or error frame or
///     - Responder sends error frame  or
///     - Requester sends payload with complete flag set AND Responder sends cancel frame or payload with complete flag set
internal struct ChannelTerminationBehaviour: TerminationBehaviour  {
    private enum State {
        case active
        /// the *requester* has send a terminating event and we are waiting for the *responder* to send one too
        case requesterTerminated
        /// the *responder* has send a terminating event and we are waiting for the *requester* to send one too
        case responderTerminated
    }
    private var state = State.active
    mutating func shouldTerminateAfterRequesterSent(event: TerminationEvent) -> Bool {
        switch event {
        case .cancel, .error: return true
        case .complete:
            guard state != .responderTerminated else { return true }
            state = .requesterTerminated
            return false
        }
    }
    mutating func shouldTerminateAfterResponderSent(event: TerminationEvent) -> Bool {
        switch event {
        case .error: return true
        case .cancel, .complete:
            guard state != .requesterTerminated else { return true }
            state = .responderTerminated
            return false
        }
    }
}

extension Frame {
    /// termination type of this frame, if it could terminate an active stream
    fileprivate var terminationEvent: TerminationEvent? {
        switch body {
        case let .payload(body): return body.isCompletion ? .complete : nil
        case .requestResponse: return .complete
        case .requestStream: return .complete
        case let .requestChannel(body): return body.isCompleted ? .complete : nil
        case .cancel: return .cancel
        case .error: return .error
        default: return nil
        }
    }
}

extension TerminationBehaviour {
    internal mutating func shouldTerminateAfterRequesterSent(_ frame: Frame) -> Bool {
        frame.terminationEvent.map { shouldTerminateAfterRequesterSent(event: $0) } ?? false
    }
    internal mutating func shouldTerminateAfterResponderSent(_ frame: Frame) -> Bool {
        frame.terminationEvent.map { shouldTerminateAfterResponderSent(event: $0) } ?? false
    }
}

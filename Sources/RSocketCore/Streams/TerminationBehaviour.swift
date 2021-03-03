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
    mutating func requesterSend(_ event: TerminationEvent) -> Bool
    /// - Parameter event: true if the stream should be terminated
    mutating func responderSend(_ event: TerminationEvent) -> Bool
}

internal struct RequestResponseTerminationBehaviour: TerminationBehaviour  {
    mutating func requesterSend(_ event: TerminationEvent) -> Bool {
        switch event {
        case .cancel: return true
        case .complete, .error: return false
        }
    }
    mutating func responderSend(_ event: TerminationEvent) -> Bool {
        switch event {
        case .cancel, .complete, .error: return true
        }
    }
}

internal struct StreamTerminationBehaviour: TerminationBehaviour {
    mutating func requesterSend(_ event: TerminationEvent) -> Bool {
        switch event {
        case .cancel: return true
        case .complete, .error: return false
        }
    }
    mutating func responderSend(_ event: TerminationEvent) -> Bool {
        switch event {
        case .cancel, .complete, .error: return true
        }
    }
}

internal struct ChannelTerminationBehaviour: TerminationBehaviour  {
    private enum State {
        case active
        case requesterTerminated
        case responderTerminated
    }
    private var state = State.active
    mutating func requesterSend(_ event: TerminationEvent) -> Bool {
        switch event {
        case .cancel, .error: return true
        case .complete:
            guard state != .responderTerminated else { return true }
            state = .requesterTerminated
            return false
        }
    }
    mutating func responderSend(_ event: TerminationEvent) -> Bool {
        switch event {
        case .error: return true
        case .cancel, .complete:
            guard state != .requesterTerminated else { return true }
            state = .requesterTerminated
            return false
        }
    }
}



extension Frame {
    fileprivate var terminationEvent: TerminationEvent? {
        switch body {
        case let .payload(body):
            return body.isCompletion ? .complete : nil
        case let .requestChannel(body):
            return body.isCompleted ? .complete : nil
        case .cancel: return .cancel
        case .error: return .error
        default: return nil
        }
    }
}

extension TerminationBehaviour {
    internal mutating func requesterSend(frame: Frame) -> Bool {
        frame.terminationEvent.map { requesterSend($0) } ?? false
    }
    internal mutating func responderSend(frame: Frame) -> Bool {
        frame.terminationEvent.map { responderSend($0) } ?? false
    }
}

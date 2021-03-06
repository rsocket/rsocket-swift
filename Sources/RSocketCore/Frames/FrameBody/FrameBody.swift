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

enum FrameBody: Hashable {
    /// Setup: Sent by client to initiate protocol processing
    indirect case setup(SetupFrameBody)

    /// Lease: Sent by Responder to grant the ability to send requests
    case lease(LeaseFrameBody)

    /// Keepalive: Connection keepalive
    case keepalive(KeepAliveFrameBody)

    /// Request Response: Request single response
    case requestResponse(RequestResponseFrameBody)

    /// Fire And Forget: A single one-way message
    case requestFnf(RequestFireAndForgetFrameBody)

    /// Request Stream: Request a completable stream
    case requestStream(RequestStreamFrameBody)

    /// Request Channel: Request a completable stream in both directions
    case requestChannel(RequestChannelFrameBody)

    /// Request N: Request N more items with Reactive Streams semantics
    case requestN(RequestNFrameBody)

    /// Cancel Request: Cancel outstanding request
    case cancel(CancelFrameBody)

    /**
     Payload: Payload on a stream

     For example, response to a request, or message on a channel.
     */
    case payload(PayloadFrameBody)
    
    /// Error: Error at connection or application level
    case error(ErrorFrameBody)

    /// Metadata: Asynchronous Metadata frame
    case metadataPush(MetadataPushFrameBody)

    /// Resume: Replaces SETUP for Resuming Operation (optional)
    case resume(ResumeFrameBody)

    /// Resume OK: Sent in response to a RESUME if resuming operation possible (optional)
    case resumeOk(ResumeOkFrameBody)

    /// Extension Header: Used To Extend more frame types as well as extensions
    case ext(ExtensionFrameBody)
}

extension FrameBody {
    var type: FrameType {
        switch self {
        case .setup: return .setup
        case .lease: return .lease
        case .keepalive: return .keepalive
        case .requestResponse: return .requestResponse
        case .requestFnf: return .requestFnf
        case .requestStream: return .requestStream
        case .requestChannel: return .requestChannel
        case .requestN: return .requestN
        case .cancel: return .cancel
        case .payload: return .payload
        case .error: return .error
        case .metadataPush: return .metadataPush
        case .resume: return .resume
        case .resumeOk: return .resumeOk
        case .ext: return .ext
        }
    }
}

extension FrameBody {
    func header(withStreamId streamId: StreamID) -> FrameHeader {
        switch self {
        case let .setup(body): return body.header(withStreamId: streamId)
        case let .lease(body): return body.header(withStreamId: streamId)
        case let .keepalive(body): return body.header(withStreamId: streamId)
        case let .requestResponse(body): return body.header(withStreamId: streamId)
        case let .requestFnf(body): return body.header(withStreamId: streamId)
        case let .requestStream(body): return body.header(withStreamId: streamId)
        case let .requestChannel(body): return body.header(withStreamId: streamId)
        case let .requestN(body): return body.header(withStreamId: streamId)
        case let .cancel(body): return body.header(withStreamId: streamId)
        case let .payload(body): return body.header(withStreamId: streamId)
        case let .error(body): return body.header(withStreamId: streamId)
        case let .metadataPush(body): return body.header(withStreamId: streamId)
        case let .resume(body): return body.header(withStreamId: streamId)
        case let .resumeOk(body): return body.header(withStreamId: streamId)
        case let .ext(body): return body.header(withStreamId: streamId)
        }
    }
}

extension FrameBody {
    /// If the frame can be ignored
    var canBeIgnored: Bool {
        guard case let .ext(body) = self else { return false }
        return body.canBeIgnored
    }
}

extension FrameBody {
    /// If true, this is a fragment and at least another payload frame will follow
    var fragmentsFollows: Bool {
        switch self {
        case let .requestResponse(body): return body.fragmentFollows
        case let .requestFnf(body): return body.fragmentFollows
        case let .requestStream(body): return body.fragmentFollows
        case let .requestChannel(body): return body.fragmentFollows
        case let .payload(body): return body.fragmentFollows
        default: return false
        }
    }
}

/// creates a description of `body` which looks like the description of an enum where each property of the body is an associated value.
/// It also removes the redundant `FrameBody` suffix from each type name.
/// - `PayloadFrameBody(isComplete: true, isNext: false)` will be transformed into `".payload(isComplete: true, isNext: false)"`
fileprivate func descriptionOfBody<T>(_ body: T) -> String {
    let typeName = normalizeFrameBodyTypeName(T.self)
    return ".\(typeName)(\(descriptionsOfProperties(body)))"
}

/// lowercases the first char of the type name of `T` and removes the `FrameBody` suffix.
/// - e.g. `RequestResponseFrameBody` becomes `"requestResponse"`
fileprivate func normalizeFrameBodyTypeName<T>(_ type: T.Type) -> String {
    let name = String(describing: T.self)
    guard let firstChar = name.first else { return name }
    return String(firstChar.lowercased() + name.dropFirst().replacingOccurrences(of: "FrameBody", with: ""))
}

/// creates a description of all stored properties in the usual format. Property name and value are delimited by `: ` and are then joined by `, `.
/// - e.g. PayloadFrameBody(isComplete: true, isNext: false) becomes `"isComplete: true, isNext: false"`
fileprivate func descriptionsOfProperties<T>(_ body: T) -> String {
    Mirror(reflecting: body).children.compactMap({
        guard let label = $0.label else { return nil }
        return "\(label): \(debugDescription(of: $0.value))"
    }).joined(separator: ", ")
}

fileprivate func debugDescription(of value: Any) -> String {
    (value as? CustomDebugStringConvertible)?.debugDescription ?? String(describing: value)
}

extension FrameBody: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case let .setup(body): return descriptionOfBody(body)
        case let .lease(body): return descriptionOfBody(body)
        case let .keepalive(body): return descriptionOfBody(body)
        case let .requestResponse(body): return descriptionOfBody(body)
        case let .requestFnf(body): return descriptionOfBody(body)
        case let .requestStream(body): return descriptionOfBody(body)
        case let .requestChannel(body): return descriptionOfBody(body)
        case let .requestN(body): return descriptionOfBody(body)
        case let .cancel(body): return descriptionOfBody(body)
        case let .payload(body): return descriptionOfBody(body)
        case let .error(body): return descriptionOfBody(body)
        case let .metadataPush(body): return descriptionOfBody(body)
        case let .resume(body): return descriptionOfBody(body)
        case let .resumeOk(body): return descriptionOfBody(body)
        case let .ext(body): return descriptionOfBody(body)
        }
    }
}

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

public enum Frame {
    /// Setup: Sent by client to initiate protocol processing
    case setup(SetupFrame)

    /// Lease: Sent by Responder to grant the ability to send requests
    case lease(LeaseFrame)

    /// Keepalive: Connection keepalive
    case keepalive(KeepAliveFrame)

    /// Request Response: Request single response
    case requestResponse(RequestResponseFrame)

    /// Fire And Forget: A single one-way message
    case requestFnf(RequestFireAndForgetFrame)

    /// Request Stream: Request a completable stream
    case requestStream(RequestStreamFrame)

    /// Request Channel: Request a completable stream in both directions
    case requestChannel(RequestChannelFrame)

    /// Request N: Request N more items with Reactive Streams semantics
    case requestN(RequestNFrame)

    /// Cancel Request: Cancel outstanding request
    case cancel(CancelFrame)

    /// Payload: Payload on a stream. For example, response to a request, or message on a channel
    case payload(PayloadFrame)

    /// Error: Error at connection or application level
    case error(ErrorFrame)

    /// Metadata: Asynchronous Metadata frame
    case metadataPush(MetadataPushFrame)

    /// Resume: Replaces SETUP for Resuming Operation (optional)
    case resume(ResumeFrame)

    /// Resume OK: Sent in response to a RESUME if resuming operation possible (optional)
    case resumeOk(ResumeOkFrame)

    /// Extension Header: Used To Extend more frame types as well as extensions
    case ext(ExtensionFrame)
}

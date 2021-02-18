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
    case setup(SetupFrameBody)

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

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

internal enum FrameType: UInt8 {
    /// Reserved
    case reserved = 0x00

    /// Setup: Sent by client to initiate protocol processing
    case setup = 0x01

    /// Lease: Sent by Responder to grant the ability to send requests
    case lease = 0x02

    /// Keepalive: Connection keepalive
    case keepalive = 0x03

    /// Request Response: Request single response
    case requestResponse = 0x04

    /// Fire And Forget: A single one-way message
    case requestFnf = 0x05

    /// Request Stream: Request a completable stream
    case requestStream = 0x06

    /// Request Channel: Request a completable stream in both directions
    case requestChannel = 0x07

    /// Request N: Request N more items with Reactive Streams semantics
    case requestN = 0x08

    /// Cancel Request: Cancel outstanding request
    case cancel = 0x09

    /**
     Payload: Payload on a stream

     For example, response to a request, or message on a channel.
     */
    case payload = 0x0A

    /// Error: Error at connection or application level
    case error = 0x0B

    /// Metadata: Asynchronous Metadata frame
    case metadataPush = 0x0C

    /// Resume: Replaces SETUP for Resuming Operation (optional)
    case resume = 0x0D

    /// Resume OK: Sent in response to a RESUME if resuming operation possible (optional)
    case resumeOk = 0x0E

    /// Extension Header: Used To Extend more frame types as well as extensions
    case ext = 0x0F
}

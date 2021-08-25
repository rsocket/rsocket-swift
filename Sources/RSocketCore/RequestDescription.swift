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

public struct MetadataPush<Metadata> {
    public let encoder: AnyMetadataEncoder<Metadata>
}

extension MetadataPush {
    @inlinable
    public init() where Metadata == Data? {
        self.init(using: OctetStreamMetadataEncoder())
    }
    @inlinable
    public init<Encoder>(
        using metadataEncoder: Encoder
    ) where Encoder: MetadataEncoder, Encoder.Metadata == Metadata {
        encoder = metadataEncoder.eraseToAnyMetadataEncoder()
    }
    
    @inlinable
    public init<Encoder>(
        @CompositeMetadataEncoderBuilder _ makeEncoder: () -> Encoder
    ) where 
    Encoder: MetadataEncoder,
    Encoder.Metadata == Metadata
    {
        encoder = makeEncoder().eraseToAnyMetadataEncoder()
    }
}

public struct FireAndForget<Request> {
    public let encoder: AnyEncoder<Void, Request>
}

extension FireAndForget {
    @inlinable
    public init() where Request == Data {
        self.init { Encoder() }
    }

    @inlinable
    public init<Encoder>(
        @EncoderBuilder _ makeEncoder: () -> Encoder
    ) where 
    Encoder: EncoderProtocol, 
    Encoder.Metadata == Void, 
    Encoder.Data == Request 
    {
        encoder = makeEncoder().eraseToAnyEncoder()
    }
}

public struct RequestResponse<Request, Response> {
    public let encoder: AnyEncoder<Void, Request>
    public let decoder: AnyDecoder<Void, Response>
}

extension RequestResponse {
    @inlinable
    public init() where Request == Data, Response == Data {
        self.init { Coder() }
    }

    @inlinable
    public init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
    Encoder.Metadata == Void, Encoder.Data == Request,
    Decoder.Metadata == Void, Decoder.Data == Response 
    {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

public struct RequestStream<Request, Response> {
    public let encoder: AnyEncoder<Void, Request>
    public let decoder: AnyDecoder<Void, Response>
}

extension RequestStream {
    @inlinable
    public init() where Request == Data, Response == Data {
        self.init { Coder() }
    }

    @inlinable
    public init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
    Encoder.Metadata == Void, Encoder.Data == Request,
    Decoder.Metadata == Void, Decoder.Data == Response 
    {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

public struct RequestChannel<Request, Response> {
    public let encoder: AnyEncoder<Void, Request>
    public let decoder: AnyDecoder<Void, Response>
}

extension RequestChannel {
    @inlinable
    public init() where Request == Data, Response == Data {
        self.init { Coder() }
    }

    @inlinable
    public init<Encoder, Decoder>(
        @CoderBuilder _ makeCoder: () -> Coder<Decoder, Encoder>
    ) where
    Encoder.Metadata == Void, Encoder.Data == Request,
    Decoder.Metadata == Void, Decoder.Data == Response 
    {
        let coder = makeCoder()
        encoder = coder.encoder.eraseToAnyEncoder()
        decoder = coder.decoder.eraseToAnyDecoder()
    }
}

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

extension Decoders {
    public struct PreserveMetadata<Decoder>: DecoderProtocol where
    Decoder: DecoderProtocol
    {
        @usableFromInline
        internal var decoder: Decoder

        @usableFromInline
        internal init(decoder: Decoder) {
            self.decoder = decoder
        }

        @inlinable
        mutating public func decode(
            _ payload: Payload,
            encoding: ConnectionEncoding
        ) throws -> (Void, (Decoder.Metadata, Decoder.Data)) {
            return ((), try decoder.decode(payload, encoding: encoding))
        }
    }
}

extension DecoderProtocol {
    @inlinable
    public func preserveMetadata() -> Decoders.PreserveMetadata<Self> {
        .init(decoder: self)
    }
}

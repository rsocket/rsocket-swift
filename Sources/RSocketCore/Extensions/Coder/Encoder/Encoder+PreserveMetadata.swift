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

extension Encoders {
    public struct PreserveMetadata<Encoder>: EncoderProtocol where
    Encoder: EncoderProtocol
    {
        @usableFromInline
        internal var encoder: Encoder

        @usableFromInline
        internal init(encoder: Encoder) {
            self.encoder = encoder
        }

        @inlinable
        public mutating func encode(
            metadata: Void,
            data: (Encoder.Metadata, Encoder.Data),
            encoding: ConnectionEncoding
        ) throws -> Payload {
            let (metadata, data) = data
            return try encoder.encode(
                metadata: metadata,
                data: data,
                encoding: encoding
            )
        }
    }
}

extension EncoderProtocol {
    @inlinable
    public func preserveMetadata() -> Encoders.PreserveMetadata<Self> {
        .init(encoder: self)
    }
}

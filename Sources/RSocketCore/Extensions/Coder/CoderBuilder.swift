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

@resultBuilder
public enum CoderBuilder: DecoderBuilderProtocol, EncoderBuilderProtocol {
    public static func buildBlock<Decoder, Encoder>(
        _ decoder: Decoder,
        _ encoder: Encoder
    ) -> Coder<Decoder, Encoder> {
        .init(decoder: decoder, encoder: encoder)
    }
    public static func buildBlock<Decoder, Encoder>(
        _ encoder: Encoder,
        _ decoder: Decoder
    ) -> Coder<Decoder, Encoder> {
        .init(decoder: decoder, encoder: encoder)
    }
    public static func buildBlock<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoder, Encoder> {
        coder
    }
    public static func buildLimitedAvailability<T>(_ component: T) -> T {
        component
    }
    public static func buildEither<T>(first component: T) -> T {
        component
    }
    public static func buildEither<T>(second component: T) -> T {
        component
    }
}

extension CoderBuilder {
    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<Decoder, Encoder> where Decoder.Metadata == Void, Encoder.Metadata == Void {
        coder
    }
    
    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoders.PreserveMetadata<Decoder>, 
        Encoders.PreserveMetadata<Encoder>
    > {
        coder
            .mapDecoder { $0.preserveMetadata() }
            .mapEncoder { $0.preserveMetadata() }
    }
    
    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoders.EraseMetadata<Decoder>, 
        Encoders.EraseMetadata<Encoder>
    > where Decoder.Metadata: ErasableMetadata, Encoder.Metadata: ErasableMetadata {
        coder
            .mapEncoder { $0.eraseMetadata() }
            .mapDecoder { $0.eraseMetadata() }
    }
    
    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoder, 
        Encoders.PreserveMetadata<Encoder>
    > where Decoder.Metadata == Void {
        coder.mapEncoder { $0.preserveMetadata() }
    }
    
    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoders.PreserveMetadata<Decoder>, 
        Encoder
    > where Encoder.Metadata == Void {
        coder.mapDecoder { $0.preserveMetadata() }
    }

    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoders.EraseMetadata<Decoder>, 
        Encoder
    > where Decoder.Metadata: ErasableMetadata, Encoder.Metadata == Void {
        coder.mapDecoder { $0.eraseMetadata() }
    }

    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoder, 
        Encoders.EraseMetadata<Encoder>
    > where Decoder.Metadata == Void, Encoder.Metadata: ErasableMetadata {
        coder.mapEncoder { $0.eraseMetadata() }
    }
    
    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoders.EraseMetadata<Decoder>, 
        Encoders.PreserveMetadata<Encoder>
    > where Decoder.Metadata: ErasableMetadata {
        coder
            .mapDecoder { $0.eraseMetadata() }
            .mapEncoder { $0.preserveMetadata() }
    }
    
    public static func buildExpression<Decoder, Encoder>(
        _ coder: Coder<Decoder, Encoder>
    ) -> Coder<
        Decoders.PreserveMetadata<Decoder>, 
        Encoders.EraseMetadata<Encoder>
    > where Encoder.Metadata: ErasableMetadata {
        coder
            .mapDecoder { $0.preserveMetadata() }
            .mapEncoder { $0.eraseMetadata() }
    }
}

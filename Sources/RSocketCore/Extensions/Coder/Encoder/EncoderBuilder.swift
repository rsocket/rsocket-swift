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
public enum EncoderBuilder: EncoderBuilderProtocol {
    public static func buildBlock<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: EncoderProtocol {
        encoder
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

public protocol EncoderBuilderProtocol {}

public extension EncoderBuilderProtocol {
    static func buildExpression<Encoder>(
        _ encoder: Encoder
    ) -> Encoders.PreserveMetadata<Encoder> {
        encoder.preserveMetadata()
    }
    static func buildExpression<Encoder>(
        _ encoder: Encoder
    ) -> Encoder where Encoder: EncoderProtocol, Encoder.Metadata == Void {
        encoder
    }
    static func buildExpression<Encoder>(
        _ encoder: Encoder
    ) -> Encoders.EraseMetadata<Encoder> where Encoder.Metadata: ErasableMetadata {
        encoder.eraseMetadata()
    }
}

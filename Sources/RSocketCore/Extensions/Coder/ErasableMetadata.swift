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


/// `ErasableMetadata` is a marker protocol used by `CoderBuilder`, `EncoderBuilder` or `DecoderBuilder` to automatically erase or preserve Metadata. 
/// If a type conforms to `ErasableMetadata` like `Data?` or `[CompositeMetadata]` and is the last Metadata, it is erased i.e. ignored by decoders and initialized with a default value by encoders. 
/// If Metadata is another type, it is automatically preserved and available by the caller i.e. when sending a request you also need to provide the metadata and the response contains the Metadata in addition to the Data. 
/// A user can always manually opt-out or opt-in by using ``preserveMetadata()`` or ``eraseMetadata()`` or ``setMetadata(_:)``.
public protocol ErasableMetadata {
    static var erasedValue: Self { get }
}

extension Optional: ErasableMetadata {
    public static var erasedValue: Optional<Wrapped> { nil }
}

extension Array: ErasableMetadata {
    public static var erasedValue: Array<Element> { [] }
}

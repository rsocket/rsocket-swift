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

public protocol Disposable {
    ///
    /// Cancel or dispose the underlying task or resource.
    /// <p>
    /// Implementations are required to make this method idempotent.
    ///
    /// - Returns `true` when there's a guarantee the resource or task is disposed
    func dispose() -> Bool;

    ///
    /// Optionally return `true` when the resource or task is disposed.
    ///
    /// Implementations are not required to track disposition and as such may never
    /// return `true` even when disposed. However, they MUST only return true
    /// when there's a guarantee the resource or task is disposed.
    ///
    /// - Returns `true` when there's a guarantee the resource or task is disposed.
    ///
    var isDisposed: Bool { get }
}

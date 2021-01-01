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


/// A signal that a publisher doesn’t produce additional elements, either due to
/// normal completion or an error.
public enum Completion<Failure: Swift.Error> {

    /// The publisher finished normally.
    case finished

    /// The publisher stopped publishing due to the indicated error.
    case failure(Failure)
}

extension Completion: Equatable where Failure: Equatable {}

extension Completion: Hashable where Failure: Hashable {}

extension Completion {
    private enum CodingKeys: String, CodingKey {
        case success = "success"
        case error = "error"
    }
}

extension Completion: Encodable where Failure: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .finished:
            try container.encode(true, forKey: .success)
        case .failure(let error):
            try container.encode(false, forKey: .success)
            try container.encode(error, forKey: .error)
        }
    }
}

extension Completion: Decodable where Failure: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let success = try container.decode(Bool.self, forKey: .success)
        if success {
            self = .finished
        } else {
            let error = try container.decode(Failure.self, forKey: .error)
            self = .failure(error)
        }
    }
}

extension Completion {

    /// Erases the `Failure` type to `Swift.Error`. This function exists
    /// because in Swift user-defined generic types are always
    /// [invariant](https://en.wikipedia.org/wiki/Covariance_and_contravariance_(computer_science)).
    internal func eraseError() -> Completion<Swift.Error> {
        switch self {
        case .finished:
            return .finished
        case .failure(let error):
            return .failure(error)
        }
    }
}

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

public protocol Subscriber {

    /// The kind of values this subscriber receives.
    associatedtype Input

    /// The kind of errors this subscriber might receive.
    ///
    /// Use `Never` if this `Subscriber` cannot receive errors.
    associatedtype Failure: Swift.Error

    /// Tells the subscriber that it has successfully subscribed to the publisher and may
    /// request items.
    ///
    /// Use the received `Subscription` to request items from the publisher.
    /// - Parameter subscription: A subscription that represents the connection between
    ///   publisher and subscriber.
    func receive(subscription: Subscription)

    /// Tells the subscriber that the publisher has produced an element.
    ///
    /// - Parameter input: The published element.
    /// - Returns: A `Subscribers.Demand` instance indicating how many more elements
    ///   the subscriber expects to receive.
    func receive(_ input: Input) -> Demand

    /// Tells the subscriber that the publisher has completed publishing, either normally
    /// or with an error.
    ///
    /// - Parameter completion: A `Subscribers.Completion` case indicating whether
    ///   publishing completed normally or with an error.
    func receive(completion: Completion<Failure>)
}

extension Subscriber where Input == Void {

    /// Tells the subscriber that a publisher of void elements is ready to receive further
    /// requests.
    ///
    /// Use `Void` inputs and outputs when you want to signal that an event has occurred,
    /// but don’t need to send the event itself.
    /// - Returns: A `Subscribers.Demand` instance indicating how many more elements
    /// the subscriber expects to receive.
    public func receive() -> Demand {
        return receive(())
    }
}

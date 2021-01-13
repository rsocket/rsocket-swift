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

internal struct EmptySubscription: Subscription {
    static let instance = EmptySubscription()

    func request(_ demand: Demand) {
    }

    func cancel() {
    }
}

internal struct ErrorPublisher<Output, Failure: Swift.Error>: SinglePublisher {
    typealias Output = Output
    typealias Failure = Failure

    let failure: Failure

    func receive<TSubscriber: Subscriber>(subscriber: TSubscriber) where Failure == TSubscriber.Failure, Output == TSubscriber.Input {
        subscriber.receive(subscription: EmptySubscription.instance)
        subscriber.receive(completion: .failure(failure))
    }
}


internal extension Publisher {
    /// Wraps this publisher with a type eraser.
    ///
    /// Use `eraseToAnyPublisher()` to expose an instance of `AnyPublisher` to
    /// the downstream subscriber, rather than this publisher’s actual type.
    /// This form of _type erasure_ preserves abstraction across API boundaries, such as
    /// different modules.
    /// When you expose your publishers as the `AnyPublisher` type, you can change
    /// the underlying implementation over time without affecting existing clients.
    ///
    /// The following example shows two types that each have a `publisher` property.
    /// `TypeWithSubject` exposes this property as its actual type, `PassthroughSubject`,
    /// while `TypeWithErasedSubject` uses `eraseToAnyPublisher()` to expose it as
    /// an `AnyPublisher`. As seen in the output, a caller from another module can access
    /// `TypeWithSubject.publisher` as its native type. This means you can’t change your
    /// publisher to a different type without breaking the caller. By comparison,
    /// `TypeWithErasedSubject.publisher` appears to callers as an `AnyPublisher`, so you
    /// can change the underlying publisher type at will.
    ///
    ///     public class TypeWithSubject {
    ///         public let publisher: some Publisher = PassthroughSubject<Int,Never>()
    ///     }
    ///     public class TypeWithErasedSubject {
    ///         public let publisher: some Publisher = PassthroughSubject<Int,Never>()
    ///             .eraseToAnyPublisher()
    ///     }
    ///
    ///     // In another module:
    ///     let nonErased = TypeWithSubject()
    ///     if let subject = nonErased.publisher as? PassthroughSubject<Int,Never> {
    ///         print("Successfully cast nonErased.publisher.")
    ///     }
    ///     let erased = TypeWithErasedSubject()
    ///     if let subject = erased.publisher as? PassthroughSubject<Int,Never> {
    ///         print("Successfully cast erased.publisher.")
    ///     }
    ///
    ///     // Prints "Successfully cast nonErased.publisher."
    ///
    /// - Returns: An ``AnyPublisher`` wrapping this publisher.
    @inlinable
    func eraseToAnyPublisher() -> AnyPublisher<Output, Failure> {
        return .init(self)
    }
}

internal extension SinglePublisher {
    /// Wraps this publisher with a type eraser.
    ///
    /// Use `eraseToAnySinglePublisher()` to expose an instance of `AnySinglePublisher` to
    /// the downstream subscriber, rather than this publisher’s actual type.
    /// This form of _type erasure_ preserves abstraction across API boundaries, such as
    /// different modules.
    /// When you expose your publishers as the `AnySinglePublisher` type, you can change
    /// the underlying implementation over time without affecting existing clients.
    ///
    /// The following example shows two types that each have a `publisher` property.
    /// `TypeWithSubject` exposes this property as its actual type, `PassthroughSubject`,
    /// while `TypeWithErasedSubject` uses `eraseToAnySinglePublisher()` to expose it as
    /// an `AnySinglePublisher`. As seen in the output, a caller from another module can access
    /// `TypeWithSubject.publisher` as its native type. This means you can’t change your
    /// publisher to a different type without breaking the caller. By comparison,
    /// `TypeWithErasedSubject.publisher` appears to callers as an `AnySinglePublisher`, so you
    /// can change the underlying publisher type at will.
    ///
    ///     public class TypeWithSubject {
    ///         public let publisher: some SinglePublisher = PassthroughSubject<Int,Never>()
    ///     }
    ///     public class TypeWithErasedSubject {
    ///         public let publisher: some SinglePublisher = PassthroughSubject<Int,Never>()
    ///             .eraseToAnySinglePublisher()
    ///     }
    ///
    ///     // In another module:
    ///     let nonErased = TypeWithSubject()
    ///     if let subject = nonErased.publisher as? PassthroughSubject<Int,Never> {
    ///         print("Successfully cast nonErased.publisher.")
    ///     }
    ///     let erased = TypeWithErasedSubject()
    ///     if let subject = erased.publisher as? PassthroughSubject<Int,Never> {
    ///         print("Successfully cast erased.publisher.")
    ///     }
    ///
    ///     // Prints "Successfully cast nonErased.publisher."
    ///
    /// - Returns: An ``AnySinglePublisher`` wrapping this publisher.
    @inlinable
    func eraseToAnySinglePublisher() -> AnySinglePublisher<Output, Failure> {
        return .init(self)
    }
}

/// A type-erasing publisher.
///
/// Use `AnyPublisher` to wrap a publisher whose type has details you don’t want to expose
/// across API boundaries, such as different modules. Wrapping a `Subject` with
/// `AnyPublisher` also prevents callers from accessing its `send(_:)` method. When you
/// use type erasure this way, you can change the underlying publisher implementation over
/// time without affecting existing clients.
///
/// You can use the `eraseToAnyPublisher()` operator to wrap a publisher with `AnyPublisher`.
public struct AnyPublisher<Output, Failure: Swift.Error>
        : CustomStringConvertible, CustomPlaygroundDisplayConvertible {
    @usableFromInline
    internal let box: PublisherBoxBase<Output, Failure>

    /// Creates a type-erasing publisher to wrap the provided publisher.
    ///
    /// - Parameter publisher: A publisher to wrap with a type-eraser.
    @inlinable
    public init<PublisherType: Publisher>(_ publisher: PublisherType)
            where Output == PublisherType.Output, Failure == PublisherType.Failure {
        // If this has already been boxed, avoid boxing again
        if let erased = publisher as? AnyPublisher<Output, Failure> {
            box = erased.box
        } else {
            box = PublisherBox(base: publisher)
        }
    }

    public var description: String {
        return "AnyPublisher"
    }

    public var playgroundDescription: Any {
        return description
    }
}

extension AnyPublisher: Publisher {
    /// This function is called to attach the specified `Subscriber` to this `Publisher`
    /// by `subscribe(_:)`
    ///
    /// - SeeAlso: `subscribe(_:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `Publisher`.
    ///                   once attached it can begin to receive values.
    @inlinable
    public func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Output == Downstream.Input, Failure == Downstream.Failure {
        box.receive(subscriber: subscriber)
    }
}

/// A type-erasing publisher.
///
/// Use `AnySinglePublisher` to wrap a publisher whose type has details you don’t want to expose
/// across API boundaries, such as different modules. Wrapping a `Subject` with
/// `AnySinglePublisher` also prevents callers from accessing its `send(_:)` method. When you
/// use type erasure this way, you can change the underlying publisher implementation over
/// time without affecting existing clients.
///
/// You can use `eraseToAnySinglePublisher()` operator to wrap a publisher with
/// `AnySinglePublisher`.
public struct AnySinglePublisher<Output, Failure: Swift.Error>
        : CustomStringConvertible, CustomPlaygroundDisplayConvertible {
    @usableFromInline
    internal let box: SinglePublisherBoxBase<Output, Failure>

    /// Creates a type-erasing publisher to wrap the provided publisher.
    ///
    /// - Parameter publisher: A publisher to wrap with a type-eraser.
    @inlinable
    public init<PublisherType: SinglePublisher>(_ publisher: PublisherType)
            where Output == PublisherType.Output, Failure == PublisherType.Failure {
        // If this has already been boxed, avoid boxing again
        if let erased = publisher as? AnySinglePublisher<Output, Failure> {
            box = erased.box
        } else {
            box = SinglePublisherBox(base: publisher)
        }
    }

    public var description: String {
        return "AnySinglePublisher"
    }

    public var playgroundDescription: Any {
        return description
    }
}

extension AnySinglePublisher: SinglePublisher {
    /// This function is called to attach the specified `Subscriber` to this `SinglePublisher`
    /// by `subscribe(_:)`
    ///
    /// - SeeAlso: `subscribe(_:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `SinglePublisher`.
    ///                   once attached it can begin to receive values.
    @inlinable
    public func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Output == Downstream.Input, Failure == Downstream.Failure {
        box.receive(subscriber: subscriber)
    }
}

/// A type-erasing base class. Its concrete subclass is generic over the underlying
/// publisher.
@usableFromInline
internal class PublisherBoxBase<Output, Failure: Swift.Error>: Publisher {
    @inlinable
    internal init() {
    }

    @usableFromInline
    internal func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Failure == Downstream.Failure, Output == Downstream.Input {
        fatalError("Abstract method call")
    }
}

@usableFromInline
internal final class PublisherBox<PublisherType: Publisher>
        : PublisherBoxBase<PublisherType.Output, PublisherType.Failure> {
    @usableFromInline
    internal let base: PublisherType

    @inlinable
    internal init(base: PublisherType) {
        self.base = base
        super.init()
    }

    @inlinable
    override internal func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Failure == Downstream.Failure, Output == Downstream.Input {
        base.receive(subscriber: subscriber)
    }
}

/// A type-erasing base class. Its concrete subclass is generic over the underlying
/// publisher.
@usableFromInline
internal class SinglePublisherBoxBase<Output, Failure: Swift.Error>: SinglePublisher {
    @inlinable
    internal init() {
    }

    @usableFromInline
    internal func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Failure == Downstream.Failure, Output == Downstream.Input {
        fatalError("Abstract method call")
    }
}


@usableFromInline
internal final class SinglePublisherBox<PublisherType: SinglePublisher>
        : SinglePublisherBoxBase<PublisherType.Output, PublisherType.Failure> {
    @usableFromInline
    internal let base: PublisherType

    @inlinable
    internal init(base: PublisherType) {
        self.base = base
        super.init()
    }

    @inlinable
    override internal func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Failure == Downstream.Failure, Output == Downstream.Input {
        base.receive(subscriber: subscriber)
    }
}

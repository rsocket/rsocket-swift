import ReactiveSwift
@testable import RSocketCore

extension Signal.Observer: StreamInput where Value == Payload, Error == RSocketCore.Error {
    public func onNext(_ payload: Payload) {
        send(value: payload)
    }

    public func onError(_ error: Error) {
        send(error: error)
    }

    public func onComplete() {
        sendCompleted()
    }

    public func onCancel() {
        sendInterrupted()
    }

    public func onRequestN(_ requestN: Int32) {
        // backpressure is not supported by ReactiveSwift
    }

    public func onExtension(extendedType: Int32, payload: Payload, canBeIgnored: Bool) {
        guard !canBeIgnored else { return }
        send(error: .invalid(message: "Extension frame not supported"))
    }
}

private func createStream() {
    let requester = Requester(streamIdGenerator: .client, sendFrame: { _ in })
    let _ = SignalProducer<Payload, Error> { observer, lifetime in
        let output = requester.requestStream(for: .response, payload: .empty, createInput: { _ in observer })
        lifetime.observeEnded(output.sendCancel)
    }
}

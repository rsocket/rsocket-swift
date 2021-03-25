#if canImport(Network)
import Network
import ReactiveSwift
import RSocketTSChannel
import RSocketReactiveSwift
import RSocketWebSocketTransport

@available(OSX 10.14, iOS 12.0, tvOS 12.0, watchOS 6.0, *)
func t() {
    let bootstrap = ClientBootstrap(
        config: .defaultMobileToServer,
        transport: WSTransport(),
        timeout: .seconds(30),
        tlsOptions: NWProtocolTLS.Options()
    )

    let clientProducer: SignalProducer<ReactiveSwiftClient, Swift.Error> = bootstrap.connect(host: "", port: 80)

    let client: Property<ReactiveSwiftClient?> = Property(initial: nil, then: clientProducer.flatMapError { _ in .empty })

    let streamProducer: SignalProducer<Payload, Swift.Error> = client.producer.skipNil().flatMap(.latest) { $0.requester.requestStream(payload: .empty) }
}
#endif

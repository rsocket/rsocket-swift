import Foundation
import Network
import RSocketCore
import RSocketTSChannel
import ReactiveSwift
import RSocketReactiveSwift
import RSocketTCPTransport
import RSocketTestUtilities
import XCTest

final class VanillaRSocketExample: XCTestCase {
    func testExample() {
        print("test")

        let bootstrap = ClientBootstrap(
                config: ClientSetupConfig(
                        timeBetweenKeepaliveFrames: 0,
                        maxLifetime: 30_000,
                        metadataEncodingMimeType: "application/octet-stream",
                        dataEncodingMimeType: "application/octet-stream"
                ),
                transport: TCPTransport(),
                timeout: .seconds(30)
        )

        let clientProducer: SignalProducer<ReactiveSwiftClient, Swift.Error> = bootstrap.connect(host: "localhost", port: 7000)

        let client: Property<ReactiveSwiftClient?> = Property(initial: nil, then: clientProducer.flatMapError { _ in
            .empty
        })

        let streamProducer: SignalProducer<Payload, Swift.Error> = client.producer.skipNil().flatMap(.latest) {
            $0.requester.requestStream(payload: .empty)
        }
        let requestProducer: SignalProducer<Payload, Swift.Error> = client.producer.skipNil().flatMap(.latest) {
            $0.requester.requestResponse(payload: "HelloWorld")
        }

        streamProducer.logEvents(identifier: "stream1").take(first: 1).start()
        streamProducer.logEvents(identifier: "stream3").take(first: 10).start()
        streamProducer.logEvents(identifier: "stream5").take(first: 100).start()

        requestProducer.logEvents(identifier: "request7").start()
        requestProducer.logEvents(identifier: "request9").start()
        requestProducer.logEvents(identifier: "request11").start()

        sleep(999999999)
    }
}


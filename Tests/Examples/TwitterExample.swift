import Foundation
import Network
import RSocketCore
import RSocketTSChannel
import ReactiveSwift
import RSocketReactiveSwift
import RSocketWebSocketTransport
import RSocketTestUtilities
import XCTest

// the server-side code can be found here -> https://github.com/rsocket/rsocket-demo/tree/master/src/main/kotlin/io/rsocket/demo/twitter
final class TwitterExample: XCTestCase {
    func testExample() {
        let bootstrap = ClientBootstrap(
                config: ClientSetupConfig(
                        timeBetweenKeepaliveFrames: 0,
                        maxLifetime: 30_000,
                        metadataEncodingMimeType: "message/x.rsocket.routing.v0",
                        dataEncodingMimeType: "application/json"
                ),
                transport: WSTransport(),
                timeout: .seconds(30)
        )

        let clientProducer = bootstrap.connect(host: "demo.rsocket.io/rsocket", port: 80)

        let clientProperty = Property<ReactiveSwiftClient?>(initial: nil, then: clientProducer.flatMapError { _ in
            .empty
        })

        let streamSemaphore = DispatchSemaphore(value: 1)
        clientProperty.producer
                .skipNil()
                .flatMap(.latest) {
                    $0.requester.requestStream(payload: Payload(
                            metadata: route("searchTweets"),
                            data: Data("RSocket".utf8)
                    ))
                }
                .logEvents(identifier: "route.searchTweets")
                .take(first: 10000)
                .on(disposed: { streamSemaphore.signal() })
                .start()

        streamSemaphore.wait();
    }
}


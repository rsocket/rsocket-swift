import ArgumentParser
import Foundation
import ReactiveSwift
import RSocketCore
import RSocketNIOChannel
import RSocketReactiveSwift
import RSocketTCPTransport

struct VanillaClientExample: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "connects to an RSocket endpoint using TCP transport, requests a couple of streams and request responses and logs all events."
    )

    @Option
    var host = "localhost"
    
    @Option
    var port = 7000

    mutating func run() throws {
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

        let clientProducer = bootstrap.connect(host: host, port: port, uri: "")

        let client: Property<ReactiveSwiftClient?> = Property(initial: nil, then: clientProducer.flatMapError { _ in
            .empty
        })

        let streamProducer: SignalProducer<Payload, Swift.Error> = client.producer.skipNil().flatMap(.latest) {
            $0.requester.requestStream(payload: .empty)
        }
        let requestProducer: SignalProducer<Payload, Swift.Error> = client.producer.skipNil().flatMap(.latest) {
            $0.requester.requestResponse(payload: Payload(data: Data("HelloWorld".utf8)))
        }

        streamProducer.logEvents(identifier: "stream1").take(first: 1).start()
        streamProducer.logEvents(identifier: "stream3").take(first: 10).start()
        streamProducer.logEvents(identifier: "stream5").take(first: 100).start()

        requestProducer.logEvents(identifier: "request7").start()
        requestProducer.logEvents(identifier: "request9").start()
        requestProducer.logEvents(identifier: "request11").start()
        
        sleep(.max)
    }
}

VanillaClientExample.main()

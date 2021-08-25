import Foundation
import ArgumentParser
import NIOCore
import ReactiveSwift
import RSocketCore
import RSocketNIOChannel
import RSocketReactiveSwift
import RSocketWSTransport

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        guard let url = URL(string: argument) else { return nil }
        self = url
    }
    public var defaultValueDescription: String { description }
}

/// the server-side code can be found here -> https://github.com/rsocket/rsocket-demo/tree/master/src/main/kotlin/io/rsocket/demo/timer
struct TimerClientExample: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "connects to an RSocket endpoint using WebSocket transport, requests a stream at the route `timer` and logs all events."
    )
    
    @Option
    var url = URL(string: "wss://demo.rsocket.io/rsocket")!
    
    @Option(help: "maximum number of responses that are taken before it cancels the stream")
    var limit = 10000

    func run() throws {
        let bootstrap = ClientBootstrap(
            transport: WSTransport(),
            config: .mobileToServer
                .set(\.encoding.metadata, to: .messageXRSocketRoutingV0)
                .set(\.encoding.data, to: .applicationJson)
        )
        
        let client = try bootstrap.connect(to: .init(url: url)).first()!.get()

        try client.requester.build(RequestStream {
            Encoder()
                .encodeStaticMetadata("timer", using: RoutingEncoder())
            Decoder()
                .mapData { String(buffer: $0) }
        }, request: ByteBuffer())
        .logEvents(identifier: "route.timer")
        .take(first: limit)
        .wait()
        .get()
    }
}

TimerClientExample.main()

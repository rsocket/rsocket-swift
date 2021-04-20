import ArgumentParser
import Foundation
import ReactiveSwift
@testable import RSocketCore
import RSocketNIOChannel
@testable import RSocketReactiveSwift
import RSocketWSTransport

extension DataDecoder {
    static var utf8: DataDecoder<String> {
        .init(mimeType: .textPlain) { data in
            String(decoding: data, as: UTF8.self)
        }
    }
}

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
            config: ClientSetupConfig(
                timeBetweenKeepaliveFrames: 30_000,
                maxLifetime: 60_000,
                metadataEncodingMimeType: "message/x.rsocket.routing.v0",
                dataEncodingMimeType: "application/json"
            ),
            transport: WSTransport()
        )
        
        let client = try bootstrap.connect(to: .init(url: url)).first()!.get()
        
        let request = Request()
            .useCompositeMetadata()
            .encodeMetadata(["timer"], using: .routing)
            .decodeData(using: .utf8)
            .eraseMetadata()

        try client.requester.requestStream(request, data: Data())
        .logEvents(identifier: "route.timer")
        .take(first: limit)
        .wait()
        .get()
    }
}

TimerClientExample.main()

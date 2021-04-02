import ArgumentParser
import Foundation
import ReactiveSwift
import RSocketCore
import RSocketNIOChannel
import RSocketReactiveSwift
import RSocketWebSocketTransport

func route(_ route: String) -> Data {
    let encodedRoute = Data(route.utf8)
    precondition(encodedRoute.count <= Int(UInt8.max), "route is to long to be encoded")
    let encodedRouteLength = Data([UInt8(encodedRoute.count)])

    return encodedRouteLength + encodedRoute
}

/// the server-side code can be found here -> https://github.com/rsocket/rsocket-demo/tree/master/src/main/kotlin/io/rsocket/demo/timer
struct TimerClientExample: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "connects to an RSocket endpoint using WebSocket transport, requests a stream at the route `timer` and logs all events."
    )
    
    @Option
    var host = "demo.rsocket.io"
    
    @Option
    var port = 80
    
    @Option
    var uri = "/rsocket"
    
    @Option(help: "maximum number of responses that are taken before it cancels the stream")
    var limit = 10000

    func run() throws {
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

        let client = try bootstrap.connect(host: host, port: port, uri: uri).first()!.get()

        try client.requester.requestStream(payload: Payload(
            metadata: route("timer"),
            data: Data()
        ))
        .map() { String.init(decoding: $0.data, as: UTF8.self) }
        .logEvents(identifier: "route.timer")
        .take(first: limit)
        .wait()
        .get()
    }
}

TimerClientExample.main()

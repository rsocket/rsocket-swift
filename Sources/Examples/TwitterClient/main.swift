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

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        guard let url = URL(string: argument) else { return nil }
        self = url
    }
    public var defaultValueDescription: String { description }
}

/// the server-side code can be found here -> https://github.com/rsocket/rsocket-demo/tree/master/src/main/kotlin/io/rsocket/demo/twitter
struct TwitterClientExample: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "connects to an RSocket endpoint using WebSocket transport, requests a stream at the route `searchTweets` to search for tweets that match the `searchString` and logs all events."
    )
    
    @Argument(help: "used to find tweets that match the given string")
    var searchString = "spring"
    
    @Option
    var url = URL(string: "ws://demo.rsocket.io/rsocket")!
    
    @Option(help: "maximum number of tweets that are taken before it cancels the stream")
    var limit = 1000

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
        
        let client = try bootstrap.connect(to: .init(url: url)).first()!.get()

        try client.requester.requestStream(payload: Payload(
            metadata: route("searchTweets"),
            data: Data(searchString.utf8)
        ))
        .attemptMap { payload -> String in
            // pretty print json
            let json = try JSONSerialization.jsonObject(with: payload.data, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            return String(decoding: data, as: UTF8.self)
        }
        .logEvents(identifier: "route.searchTweets")
        .take(first: limit)
        .wait()
        .get()
    }
}

TwitterClientExample.main()

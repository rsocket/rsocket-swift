import ArgumentParser
import Foundation
import ReactiveSwift
import RSocketCore
import RSocketNIOChannel
import RSocketReactiveSwift
import RSocketWSTransport
import NIOCore

func route(_ route: String) throws -> ByteBuffer {
    var buffer = ByteBuffer()
    try buffer.writeLengthPrefixed(as: UInt8.self) { buffer in
        buffer.writeString(route)
    }
    return buffer
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
    var url = URL(string: "wss://demo.rsocket.io/rsocket")!
    
    @Option(help: "maximum number of tweets that are taken before it cancels the stream")
    var limit = 1000

    func run() throws {
        let bootstrap = ClientBootstrap(
            transport: WSTransport(),
            config: ClientConfiguration.mobileToServer
                .set(\.encoding.metadata, to: .messageXRSocketRoutingV0)
                .set(\.encoding.data, to: .applicationJson)
        )
        
        let client = try bootstrap.connect(to: .init(url: url)).first()!.get()

        try client.requester.requestStream(payload: Payload(
            metadata: try route("searchTweets"),
            data: ByteBuffer(bytes: searchString.utf8)
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

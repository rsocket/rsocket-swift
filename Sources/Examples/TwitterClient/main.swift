import ArgumentParser
import Foundation
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
            config: .mobileToServer
                .set(\.encoding.metadata, to: .messageXRSocketRoutingV0)
                .set(\.encoding.data, to: .applicationJson)
        )
        
        let client = try bootstrap.connect(to: .init(url: url)).first()!.get()
        try client.requester(RequestStream {
            Encoder()
                .encodeStaticMetadata("searchTweets", using: RoutingEncoder())
                .mapData { (string: String) in 
                    Data(string.utf8) 
                }
            Decoder()
                .mapData { data -> String in
                    // pretty print json
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
                    return String(decoding: data, as: UTF8.self)
                }
        }, request: searchString)
        .logEvents(identifier: "route.searchTweets")
        .take(first: limit)
        .wait()
        .get()
    }
}

TwitterClientExample.main()

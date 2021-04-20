import ArgumentParser
import Foundation
import ReactiveSwift
@testable import RSocketCore
import RSocketNIOChannel
@testable import RSocketReactiveSwift
import RSocketWSTransport

extension DataEncoder {
    static var utf8: DataEncoder<String> {
        .init(mimeType: .textPlain) { string in
            Data(string.utf8)
        }
    }
}

extension DataDecoder {
    static var utf8: DataDecoder<String> {
        .init(mimeType: .textPlain) { data in
            String(decoding: data, as: UTF8.self)
        }
    }
    static var prettyPrintedJSON: DataDecoder<String> {
        .init(mimeType: .textPlain) { data in
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            return String(decoding: data, as: UTF8.self)
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
            .encodeMetadata(["searchTweets"], using: .routing)
            .encodeData(using: .utf8)
            .decodeData(using: .prettyPrintedJSON)
            .eraseMetadata()

        try client.requester.requestStream(request, data: searchString)
            .logEvents(identifier: "route.searchTweets")
            .take(first: limit)
            .wait()
            .get()
    }
}

TwitterClientExample.main()

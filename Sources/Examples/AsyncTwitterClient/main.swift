#if compiler(>=5.5)
import ArgumentParser
import Foundation
import NIO
import RSocketAsync
import RSocketCore
import RSocketNIOChannel
import RSocketWSTransport

struct Tweet: Decodable {
    struct User: Decodable {
        let screen_name, name: String
        let followers_count: Int
    }
    let user: User
    let text: String
    let reply_count, retweet_count, favorite_count: Int
}

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        guard let url = URL(string: argument) else { return nil }
        self = url
    }
    public var defaultValueDescription: String { description }
}

/// the server-side code can be found here -> https://github.com/rsocket/rsocket-demo/tree/master/src/main/kotlin/io/rsocket/demo/twitter
@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
struct TwitterClientExample: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "connects to an RSocket endpoint using WebSocket transport, requests a stream at the route `searchTweets` to search for tweets that match the `searchString` and logs all events."
    )
    
    @Argument(help: "used to find tweets that match the given string")
    var searchString = "swift"
    
    @Option
    var url = URL(string: "wss://demo.rsocket.io/rsocket")!
    
    @Option(help: "maximum number of tweets that are taken before it cancels the stream")
    var limit = 1000

    func run() throws {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer { try! eventLoop.syncShutdownGracefully() }
        let promise = eventLoop.next().makePromise(of: Void.self)
        promise.completeWithAsync {
            try await self.runAsync()
        }
        try promise.futureResult.wait()
    }
    func runAsync() async throws {
        let bootstrap = ClientBootstrap(
            transport: WSTransport(),
            config: .mobileToServer
                .set(\.encoding.metadata, to: .messageXRSocketRoutingV0)
                .set(\.encoding.data, to: .applicationJson),
            timeout: .seconds(30)
        )
        let client = try await bootstrap.connect(to: .init(url: url), payload: .empty)

        let stream = try client.requester(
            RequestStream {
                Encoder()
                    .encodeStaticMetadata("searchTweets", using: .routing)
                    .mapData { (string: String) in Data(string.utf8) }
                Decoder()
                    .decodeData(using: JSONDataDecoder(type: Tweet.self))
            },
            request: searchString
        )
        
        for try await tweet in stream.prefix(limit) {
            dump(tweet)
        }
    }
}
if #available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *) {
    TwitterClientExample.main()
}
#endif

#if compiler(>=5.5) && $AsyncAwait
import ArgumentParser
import Foundation
import NIO
import RSocketAsync
import RSocketCore
import RSocketNIOChannel
import RSocketReactiveSwift
import RSocketWSTransport

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
@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
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
                .set(\.encoding.metadata, to: .rsocketRoutingV0)
                .set(\.encoding.data, to: .json),
            timeout: .seconds(30)
        )
        let client = try await bootstrap.connect(to: .init(url: url), payload: .empty)

        let stream = client.requester.requestStream(payload: Payload(
            metadata: route("searchTweets"),
            data: Data(searchString.utf8)
        ))
        
        for try await payload in stream.prefix(limit) {
            let json = try JSONSerialization.jsonObject(with: payload.data, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            let string = String(decoding: data, as: UTF8.self)
            print(string)
        }
    }
}
if #available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *) {
    TwitterClientExample.main()
}
#endif

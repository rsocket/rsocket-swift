import Network
import NIO
import NIOExtras
import NIOHTTP1
import NIOSSL
import NIOTransportServices
import NIOWebSocket
import RSocketCore
import ReactiveSwift
@testable import RSocketReactiveSwift

// MARK: - Client

protocol Client {
    associatedtype RSocket
    var requester: RSocket { get }
}

class CoreClient: Client {
    let requester: RSocketCore.RSocket

    init(requester: RSocketCore.RSocket) {
        self.requester = requester
    }

    deinit {
        // TODO: close channel
    }
}

protocol Bootstrap {
    associatedtype Client
    associatedtype Responder
    func connect(host: String, port: Int, responder: Responder?) -> EventLoopFuture<Client>
}

// MARK: - Network.framework

struct NFClientBootstrap: Bootstrap {
    private let group = NIOTSEventLoopGroup()
    private let bootstrap: NIOTSConnectionBootstrap
    private let config: ClientSetupConfig
    private let transport: TransportChannelHandler

    init(
        config: ClientSetupConfig,
        transport: TransportChannelHandler,
        timeout: TimeAmount = .seconds(30),
        tlsOptions: NWProtocolTLS.Options? = nil
    ) {
        self.config = config
        bootstrap = NIOTSConnectionBootstrap(group: group)
            .connectTimeout(timeout)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        if let tlsOptions = tlsOptions {
            _ = bootstrap.tlsOptions(tlsOptions)
        }
        self.transport = transport
    }

    @discardableResult
    func configure(bootstrap configure: (NIOTSConnectionBootstrap) -> NIOTSConnectionBootstrap) -> Self {
        _ = configure(bootstrap)
        return self
    }

    func connect(host: String, port: Int, responder: RSocketCore.RSocket?) -> EventLoopFuture<CoreClient> {
        let requesterPromise = group.next().makePromise(of: RSocketCore.RSocket.self)

        let connectFuture = bootstrap
            .channelInitializer { channel in
                transport.addChannelHandler(channel: channel, host: host, port: port) {
                    channel.pipeline.addRSocketClientHandlers(
                        config: config,
                        responder: responder,
                        connectedPromise: requesterPromise
                    )
                }
            }
            .connect(host: host, port: port)

        return connectFuture
            .flatMap { _ in requesterPromise.futureResult }
            .map(CoreClient.init)
    }
}

// MARK: - Bercley Sockets

protocol TransportChannelHandler {
    func addChannelHandler(
        channel: Channel,
        host: String,
        port: Int,
        upgradeComplete: @escaping () -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void>
}

struct TSClientBootstrap: Bootstrap {
    private let group = NIOTSEventLoopGroup()
    private let bootstrap: ClientBootstrap
    private let config: ClientSetupConfig
    private let sslContext: NIOSSLContext?
    private let transport: TransportChannelHandler

    init(
        config: ClientSetupConfig,
        transport: TransportChannelHandler,
        timeout: TimeAmount = .seconds(30),
        sslContext: NIOSSLContext? = nil
    ) {
        self.config = config
        bootstrap = ClientBootstrap(group: group)
            .connectTimeout(timeout)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        self.sslContext = sslContext
        self.transport = transport
    }

    @discardableResult
    func configure(bootstrap configure: (ClientBootstrap) -> ClientBootstrap) -> Self {
        _ = configure(bootstrap)
        return self
    }

    func connect(host: String, port: Int, responder: RSocketCore.RSocket?) -> EventLoopFuture<CoreClient> {
        let requesterPromise = group.next().makePromise(of: RSocketCore.RSocket.self)

        let connectFuture = bootstrap
            .channelInitializer { channel in
                let otherHandlersBlock: () -> EventLoopFuture<Void> = {
                    transport.addChannelHandler(channel: channel, host: host, port: port) {
                        channel.pipeline.addRSocketClientHandlers(
                            config: config,
                            responder: responder,
                            connectedPromise: requesterPromise
                        )
                    }
                }
                if let sslContext = sslContext {
                    do {
                        let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: host)
                        return channel.pipeline.addHandler(sslHandler).flatMap(otherHandlersBlock)
                    } catch {
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                } else {
                    return otherHandlersBlock()
                }
            }
            .connect(host: host, port: port)

        return connectFuture
            .flatMap { _ in requesterPromise.futureResult }
            .map(CoreClient.init)
    }
}

struct TCPTransport: TransportChannelHandler {
    func addChannelHandler(
        channel: Channel,
        host: String,
        port: Int,
        upgradeComplete: @escaping () -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        channel.pipeline.addHandlers([
            ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
            LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
        ]).flatMap(upgradeComplete)
    }
}

struct WSTransport: TransportChannelHandler {
    func addChannelHandler(
        channel: Channel,
        host: String,
        port: Int,
        upgradeComplete: @escaping () -> EventLoopFuture<Void>
    ) -> EventLoopFuture<Void> {
        let httpHandler = HTTPInitialRequestHandler(host: host, port: port)
        let websocketUpgrader = NIOWebSocketClientUpgrader(
            requestKey: "OfS0wDaT5NoxF2gqm7Zj2YtetzM=", // TODO
            upgradePipelineHandler: { _, _ in
                upgradeComplete()
            }
        )
        let config: NIOHTTPClientUpgradeConfiguration = (
            upgraders: [websocketUpgrader],
            completionHandler: { _ in
                channel.pipeline.removeHandler(httpHandler, promise: nil)
            }
        )
        return channel.pipeline
            .addHTTPClientHandlers(withClientUpgrade: config)
            .flatMap { channel.pipeline.addHandler(httpHandler) }
    }
}

private final class HTTPInitialRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
    public typealias InboundIn = HTTPClientResponsePart
    public typealias OutboundOut = HTTPClientRequestPart

    private let host: String
    private let port: Int

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    public func channelActive(context: ChannelHandlerContext) {
        print("Client connected to \(context.remoteAddress!)")

        // We are connected. It's time to send the message to the server to initialize the upgrade dance.
        var headers = HTTPHeaders()
        headers.add(name: "Host", value: "\(host):\(port)")
        headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
        headers.add(name: "Content-Length", value: "\(0)")

        let requestHead = HTTPRequestHead(version: .http1_1,
                                          method: .GET,
                                          uri: "/",
                                          headers: headers)

        context.write(self.wrapOutboundOut(.head(requestHead)), promise: nil)

        let body = HTTPClientRequestPart.body(.byteBuffer(ByteBuffer()))
        context.write(self.wrapOutboundOut(body), promise: nil)

        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {

        let clientResponse = self.unwrapInboundIn(data)

        print("Upgrade failed")

        switch clientResponse {
        case .head(let responseHead):
            print("Received status: \(responseHead.status)")
        case .body(let byteBuffer):
            let string = String(buffer: byteBuffer)
            print("Received: '\(string)' back from the server.")
        case .end:
            print("Closing channel.")
            context.close(promise: nil)
        }
    }

    public func handlerRemoved(context: ChannelHandlerContext) {
        print("HTTP handler removed.")
    }

    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: ", error)

        // As we are not really interested getting notified on success or failure
        // we just pass nil as promise to reduce allocations.
        context.close(promise: nil)
    }
}

// MARK: - ReactiveSwift

struct ReactiveSwiftClient: Client {
    private let coreClient: CoreClient

    var requester: RSocketReactiveSwift.RSocket { coreClient.requester.reactive }

    init(_ coreClient: CoreClient) {
        self.coreClient = coreClient
    }
}

extension Bootstrap where Client == CoreClient, Responder == RSocketCore.RSocket  {
    func connect(host: String, port: Int, responder: RSocketReactiveSwift.RSocket? = nil) -> SignalProducer<ReactiveSwiftClient, Swift.Error> {
        SignalProducer { observer, lifetime in
            let future = connect(host: host, port: port, responder: responder?.asCore)
                .map(ReactiveSwiftClient.init)
            future.whenComplete { result in
                switch result {
                case let .success(client):
                    observer.send(value: client)
                    observer.sendCompleted()
                case let .failure(error):
                    observer.send(error: error)
                }
            }
        }
    }
}

// MARK: - Client

let bootstrap = NFClientBootstrap(
    config: .defaultMobileToServer,
    transport: TCPTransport(),
    timeout: .seconds(30),
    tlsOptions: NWProtocolTLS.Options()
)

let clientProducer: SignalProducer<ReactiveSwiftClient, Swift.Error> = bootstrap.connect(host: "", port: 80)

let client: Property<ReactiveSwiftClient?> = Property(initial: nil, then: clientProducer.flatMapError { _ in .empty })

let streamProducer: SignalProducer<Payload, Swift.Error> = client.value!.requester.requestStream(payload: .empty)

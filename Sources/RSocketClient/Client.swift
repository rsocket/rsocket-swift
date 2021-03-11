import Network
import NIO
import NIOExtras
import NIOTransportServices
import RSocketCore
import ReactiveSwift
@testable import RSocketReactiveSwift

// MARK: - Client

protocol Client {
    associatedtype RSocket
    var requester: RSocket { get }
}

struct CoreClient: Client {
    let requester: RSocketCore.RSocket
}

protocol Bootstrap {
    associatedtype Client
    associatedtype Responder
    func connect(host: String, port: Int, responder: Responder?) -> EventLoopFuture<Client>
}

// MARK: - Transport

struct NFClientBootstrap: Bootstrap {
    private let group = NIOTSEventLoopGroup()
    private let bootstrap: NIOTSConnectionBootstrap
    private let config: ClientSetupConfig
    var transportChannelHandlers: [ChannelHandler] = []
    init(
        config: ClientSetupConfig,
        timeout: TimeAmount = .seconds(30),
        tlsOptions: NWProtocolTLS.Options? = nil
    ) {
        self.config = config
        bootstrap = NIOTSConnectionBootstrap(group: group)
            .connectTimeout(.hours(1))
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        if let tlsOptions = tlsOptions {
            _ = bootstrap.tlsOptions(tlsOptions)
        }
    }

    func connect(host: String, port: Int, responder: RSocketCore.RSocket?) -> EventLoopFuture<CoreClient> {
        bootstrap
            .channelInitializer { channel in
                channel.pipeline.addHandlers(transportChannelHandlers).flatMap {
                    channel.pipeline.addRSocketClientHandlers(config: config)
                }
            }
            .connect(host: host, port: port)
            .flatMap(\.pipeline.requester)
            .map(CoreClient.init)
    }
}

extension NFClientBootstrap {
    func useTCP() -> Self {
        var copy = self
        copy.transportChannelHandlers += [
            ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldBitLength: .threeBytes)),
            LengthFieldPrepender(lengthFieldBitLength: .threeBytes),
        ]
        return copy
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
    func connect(host: String, port: Int, responder: RSocketReactiveSwift.RSocket? = nil) -> EventLoopFuture<ReactiveSwiftClient> {
        connect(host: host, port: port, responder: responder?.asCore)
            .map(ReactiveSwiftClient.init)
    }
}

// MARK: - Client

let bootstrap = NFClientBootstrap(
    config: ClientSetupConfig(
        timeBetweenKeepaliveFrames: 500,
        maxLifetime: 500,
        metadataEncodingMimeType: "",
        dataEncodingMimeType: ""
    ),
    timeout: .seconds(30),
    tlsOptions: NWProtocolTLS.Options()
).useTCP()

let client: ReactiveSwiftClient = try! bootstrap
    .connect(host: "", port: 80)
    .wait()

let streamProducer: SignalProducer<Payload, Swift.Error> = client.requester.requestStream(payload: .empty)

// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "RSocket",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2)
    ],
    products: [
        .library(name: "UserCode", targets: ["UserCode"]),

        // Core
        .library(name: "RSocketCore", targets: ["RSocketCore"]),

        // Reactive streams
        .library(name: "RSocketCombine", targets: ["RSocketCombine"]),
        .library(name: "RSocketReactiveSwift", targets: ["RSocketReactiveSwift"]),

        // Socket implementation
        .library(name: "RSocketTSChannel", targets: ["RSocketTSChannel"]),
        .library(name: "RSocketNIOChannel", targets: ["RSocketNIOChannel"]),

        // Transport protocol
        .library(name: "RSocketWebSocketTransport", targets: ["RSocketWebSocketTransport"]),
        .library(name: "RSocketTCPTransport", targets: ["RSocketTCPTransport"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.6.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.26.0"),
        .package(url: "https://github.com/apple/swift-nio-extras", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", from: "1.9.2"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.10.4")
    ],
    targets: [
        .target(name: "UserCode", dependencies: [
            "RSocketTSChannel",
            "RSocketWebSocketTransport",
            "RSocketReactiveSwift",
            .product(name: "ReactiveSwift", package: "ReactiveSwift")
        ]),

        // Core
        .target(name: "RSocketCore", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOFoundationCompat", package: "swift-nio"),
        ]),

        // Reactive streams
        .target(name: "RSocketCombine", dependencies: ["RSocketCore"]),
        .target(name: "RSocketReactiveSwift", dependencies: [
            "RSocketCore",
            .product(name: "ReactiveSwift", package: "ReactiveSwift")
        ]),

        // Channel
        .target(name: "RSocketTSChannel", dependencies: [
            "RSocketCore",
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services")
        ]),
        .target(name: "RSocketNIOChannel", dependencies: [
            "RSocketCore",
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl")
        ]),

        // Transport protocol
        .target(name: "RSocketWebSocketTransport", dependencies: [
            "RSocketCore",
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            .product(name: "NIOWebSocket", package: "swift-nio"),
        ]),
        .target(name: "RSocketTCPTransport", dependencies: [
            "RSocketCore",
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOExtras", package: "swift-nio-extras")
        ]),

        // Tests
        .target(name: "RSocketTestUtilities", dependencies: ["RSocketCore"]),
        .testTarget(name: "RSocketCoreTests", dependencies: [
            "RSocketCore",
            "RSocketTestUtilities",
            .product(name: "NIOExtras", package: "swift-nio-extras"),
        ]),
        .testTarget(name: "RSocketCorePerformanceTests", dependencies: [
            "RSocketCore",
            "RSocketTestUtilities",
            .product(name: "NIOExtras", package: "swift-nio-extras"),
        ]),
        .testTarget(name: "RSocketCombineTests", dependencies: ["RSocketCombine"]),
        .testTarget(name: "RSocketReactiveSwiftTests", dependencies: [
            "RSocketCore",
            "RSocketReactiveSwift",
            "RSocketTestUtilities",
            "ReactiveSwift",
            .product(name: "NIO", package: "swift-nio"),
        ]),
    ],
    swiftLanguageVersions: [.v5]
)

// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "RSocket",
    products: [
        // Core
        .library(name: "RSocketCore", targets: ["RSocketCore"]),

        // Reactive streams
        .library(name: "RSocketCombine", targets: ["RSocketCombine"]),
        .library(name: "RSocketReactiveSwift", targets: ["RSocketReactiveSwift"]),

        // Socket implementation
        .library(name: "RSocketTSChannel", targets: ["RSocketTSChannel"]),
        .library(name: "RSocketNIOChannel", targets: ["RSocketNIOChannel"]),

        // Transport protocol
        .library(name: "RSocketWSTransport", targets: ["RSocketWSTransport"]),
        .library(name: "RSocketTCPTransport", targets: ["RSocketTCPTransport"]),
        
        // Examples
        .executable(name: "timer-client-example", targets: ["TimerClientExample"]),
        .executable(name: "twitter-client-example", targets: ["TwitterClientExample"]),
        .executable(name: "vanilla-client-example", targets: ["VanillaClientExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.6.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.30.0"),
        .package(url: "https://github.com/apple/swift-nio-extras", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services", from: "1.9.2"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.10.4"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
    ],
    targets: [
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
        .target(name: "RSocketWSTransport", dependencies: [
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
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
        ]),
        .testTarget(name: "RSocketCorePerformanceTests", dependencies: [
            "RSocketCore",
            "RSocketTestUtilities",
            .product(name: "NIOExtras", package: "swift-nio-extras"),
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
        ]),
        .testTarget(name: "RSocketCombineTests", dependencies: ["RSocketCombine"]),
        .testTarget(name: "RSocketReactiveSwiftTests", dependencies: [
            "RSocketCore",
            "RSocketReactiveSwift",
            "RSocketTestUtilities",
            "ReactiveSwift",
            .product(name: "NIO", package: "swift-nio"),
        ]),
        .testTarget(name: "RSocketWSTransportTests", dependencies: [
            "RSocketWSTransport"
        ]),
        
        // Examples
        .executableTarget(
            name: "TimerClientExample",
            dependencies: [
                "RSocketCore",
                "RSocketNIOChannel",
                "RSocketWSTransport",
                "RSocketReactiveSwift",
                .product(name: "ReactiveSwift", package: "ReactiveSwift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/Examples/TimerClient"
        ),
        .executableTarget(
            name: "TwitterClientExample",
            dependencies: [
                "RSocketCore",
                "RSocketNIOChannel",
                "RSocketWSTransport",
                "RSocketReactiveSwift",
                .product(name: "ReactiveSwift", package: "ReactiveSwift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/Examples/TwitterClient"
        ),
        .executableTarget(
            name: "VanillaClientExample",
            dependencies: [
                "RSocketCore",
                "RSocketNIOChannel",
                "RSocketTCPTransport",
                "RSocketReactiveSwift",
                .product(name: "ReactiveSwift", package: "ReactiveSwift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/Examples/VanillaClient"
        ),
    ],
    swiftLanguageVersions: [.v5]
)

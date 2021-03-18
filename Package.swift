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
        .library(name: "RSocketNetworkFrameworkTransport", targets: ["RSocketNetworkFrameworkTransport"]),
        .library(name: "RSocketFoundationTransport", targets: ["RSocketFoundationTransport"]),

        // Transport protocol
        .library(name: "RSocketWebSocket", targets: ["RSocketWebSocket"]),
        .library(name: "RSocketTCP", targets: ["RSocketTCP"])
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
            "RSocketNetworkFrameworkTransport",
            "RSocketWebSocket",
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

        // Socket implementation
        .target(name: "RSocketNetworkFrameworkTransport", dependencies: [
            "RSocketCore",
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services")
        ]),
        .target(name: "RSocketFoundationTransport", dependencies: [
            "RSocketCore",
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl")
        ]),

        // Transport protocol
        .target(name: "RSocketWebSocket", dependencies: [
            "RSocketCore",
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            .product(name: "NIOWebSocket", package: "swift-nio"),
        ]),
        .target(name: "RSocketTCP", dependencies: [
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

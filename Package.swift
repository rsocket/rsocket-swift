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
        .library(name: "RSocketCore", targets: ["RSocketCore"]),
        .library(name: "RSocketCombine", targets: ["RSocketCombine"]),
        .library(name: "RSocketReactiveSwift", targets: ["RSocketReactiveSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.5.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.25.1"),
    ],
    targets: [
        .target(name: "RSocketCore", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOFoundationCompat", package: "swift-nio"),
        ]),
        .target(name: "RSocketCombine", dependencies: ["RSocketCore"]),
        .target(name: "RSocketReactiveSwift", dependencies: ["RSocketCore", "ReactiveSwift"]),
        .testTarget(name: "RSocketCoreTests", dependencies: ["RSocketCore"]),
        .testTarget(name: "RSocketCombineTests", dependencies: ["RSocketCombine"]),
        .testTarget(name: "RSocketReactiveSwiftTests", dependencies: ["RSocketReactiveSwift"])
    ],
    swiftLanguageVersions: [.v5]
)

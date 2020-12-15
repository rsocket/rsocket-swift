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
        .library(name: "RSocket", targets: ["RSocket"]),
        .library(name: "RSocketCombine", targets: ["RSocketCombine"]),
        .library(name: "RSocketReactiveSwift", targets: ["RSocketReactiveSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "6.5.0"),
    ],
    targets: [
        .target(name: "RSocket", dependencies: []),
        .target(name: "RSocketCombine", dependencies: ["RSocket"]),
        .target(name: "RSocketReactiveSwift", dependencies: ["RSocket", "ReactiveSwift"]),
        .testTarget(name: "RSocketTests", dependencies: ["RSocket"]),
        .testTarget(name: "RSocketCombineTests", dependencies: ["RSocketCombine"]),
        .testTarget(name: "RSocketReactiveSwiftTests", dependencies: ["RSocketReactiveSwift"])
    ],
    swiftLanguageVersions: [.v5]
)

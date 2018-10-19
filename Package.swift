// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BookishCore",
    products: [
        .library(
            name: "BookishCore",
            targets: ["BookishCore"])
    ],
    dependencies: [
        .package(url: "git@github.com:elegantchaos/Logger", from: "1.0.11"),
        .package(url: "git@github.com:elegantchaos/Actions", from: "1.0.6"),
        .package(url: "git@github.com:elegantchaos/SketchX", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "BookishCore",
            dependencies: ["Logger", "Actions", "ActionsKit"]),
        .testTarget(
            name: "BookishCoreTests",
            dependencies: ["BookishCore", "Actions"]),
        ],
    swiftLanguageVersions: [.v4_2]
)

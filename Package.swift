// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BookishCore",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "SketchExporter",
            targets: ["SketchExporter"]),
        .library(
            name: "BookishCore",
            targets: ["BookishCore"])
    ],
    dependencies: [
        .package(url: "git@github.com:elegantchaos/Logger", from: "1.0.11"),
        .package(url: "git@github.com:elegantchaos/Actions", from: "1.0.5"),
        .package(url: "git@github.com:elegantchaos/SketchX", from: "1.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SketchExporter",
            dependencies: []),
        .target(
            name: "BookishCore",
            dependencies: ["Logger", "Actions", "ActionsKit"]),
        .testTarget(
            name: "BookishCoreTests",
            dependencies: ["BookishCore", "Actions"]),
        ],
    swiftLanguageVersions: [.v4_2]
)

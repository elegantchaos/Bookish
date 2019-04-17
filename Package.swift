// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BookishCore",
    dependencies: [
        .package(url: "git@github.com:elegantchaos/SketchX", from: "1.0.2"),
        .package(url: "git@github.com:elegantchaos/ReleaseTools", .branch("master")),
    ],
    targets: [
        ],
    swiftLanguageVersions: [.v4_2]
)

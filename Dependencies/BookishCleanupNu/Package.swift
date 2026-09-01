// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishCleanup",
  platforms: [
    .macOS(.v26), .iOS(.v26)
  ],
  products: [
    .library(
      name: "BookishCleanup",
      targets: ["BookishCleanup"])
  ],

  dependencies: [
    .package(url: "https://github.com/elegantchaos/ElegantStrings.git", from: "1.0.2"),
    .package(url: "https://github.com/elegantchaos/Expressions.git", from: "1.1.1"),
    .package(url: "https://github.com/elegantchaos/Logger.git", from: "2.0.0"),
  ],

  targets: [
    .target(
      name: "BookishCleanup",
      dependencies: ["ElegantStrings", "Expressions", "Logger"]
    ),

    .testTarget(
      name: "BookishCleanupTests",
      dependencies: ["BookishCleanup"]
    ),
  ]
)

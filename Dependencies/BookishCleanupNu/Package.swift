// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "BookishCleanup",
  platforms: [
    .macOS("15.0"),
    .iOS(.v16), .macCatalyst(.v16),
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

// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishCapture",
  platforms: [
    .macOS(.v26), .iOS(.v26),
  ],
  products: [
    .library(
      name: "BookishCapture",
      targets: ["BookishCapture"]
    )
  ],

  dependencies: [
    .package(path: "../Keychain"),
    .package(url: "https://github.com/elegantchaos/Logger.git", from: "2.0.0")
  ],

  targets: [
    .target(
      name: "BookishCapture",
      dependencies: [
        .product(name: "Logger", package: "Logger"),
        .product(name: "Keychain", package: "Keychain"),
      ]
    ),

    .testTarget(
      name: "BookishCaptureTests",
      dependencies: ["BookishCapture"]
    ),
  ]
)

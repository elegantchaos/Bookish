// swift-tools-version:6.4

import PackageDescription

let package = Package(
  name: "BookishRecognition",
  platforms: [
    .macOS(.v26), .iOS(.v26),
  ],
  products: [
    .library(
      name: "BookishRecognition",
      targets: ["BookishRecognition"]
    )
  ],

  dependencies: [
    .package(url: "https://github.com/elegantchaos/Logger.git", from: "2.0.0")
  ],

  targets: [
    .target(
      name: "BookishRecognition",
      dependencies: [
        .product(name: "Logger", package: "Logger")
      ]
    ),

    .testTarget(
      name: "BookishRecognitionTests",
      dependencies: ["BookishRecognition"]
    ),
  ]
)

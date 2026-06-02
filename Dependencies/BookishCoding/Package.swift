// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishCoding",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "BookishCoding",
      targets: ["BookishCoding"]
    )
  ],
  dependencies: [
    .package(path: "../BookishRecord")
  ],
  targets: [
    .target(
      name: "BookishCoding",
      dependencies: [
        .product(name: "BookishRecord", package: "BookishRecord")
      ]
    ),
    .testTarget(
      name: "BookishCodingTests",
      dependencies: ["BookishCoding"]
    ),
  ]
)

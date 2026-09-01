// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishDatastore",
  platforms: [
    .macOS(.v26), .iOS(.v26)
  ],
  products: [
    .library(
      name: "BookishDatastore",
      targets: ["BookishDatastore"]
    )
  ],
  dependencies: [
    .package(path: "../BookishRecord")
  ],
  targets: [
    .target(
      name: "BookishDatastore",
      dependencies: [
        .product(name: "BookishRecord", package: "BookishRecord")
      ]
    ),
    .testTarget(
      name: "BookishDatastoreTests",
      dependencies: [
        "BookishDatastore",
        .product(name: "BookishRecord", package: "BookishRecord"),
      ]
    ),
  ]
)

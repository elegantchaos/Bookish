// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishRecordView",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "BookishRecordView",
      targets: ["BookishRecordView"]
    )
  ],
  dependencies: [
    .package(path: "../BookishRecord"),
    .package(path: "../BookishDatastore"),
  ],
  targets: [
    .target(
      name: "BookishRecordView",
      dependencies: [
        .product(name: "BookishRecord", package: "BookishRecord"),
        .product(name: "BookishDatastore", package: "BookishDatastore"),
      ]
    ),
    .testTarget(
      name: "BookishRecordViewTests",
      dependencies: [
        "BookishRecordView",
        .product(name: "BookishDatastore", package: "BookishDatastore"),
        .product(name: "BookishRecord", package: "BookishRecord"),
      ]
    ),
  ]
)

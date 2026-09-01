// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishImporterNu",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "BookishImporterNu",
      targets: ["BookishImporterNu"]
    )
  ],
  dependencies: [
    .package(path: "../BookishRecord"),
    .package(path: "../BookishCoding"),
    .package(path: "../BookishCleanupNu"),
  ],
  targets: [
    .target(
      name: "BookishImporterNu",
      dependencies: [
        .product(name: "BookishRecord", package: "BookishRecord"),
        .product(name: "BookishCoding", package: "BookishCoding"),
        .product(name: "BookishCleanup", package: "BookishCleanupNu"),
      ]
    ),
    .testTarget(
      name: "BookishImporterNuTests",
      dependencies: [
        "BookishImporterNu",
        .product(name: "BookishCoding", package: "BookishCoding"),
      ]
    ),
  ]
)

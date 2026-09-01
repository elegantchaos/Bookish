// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishApp",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "BookishApp",
      targets: ["BookishApp"]
    )
  ],
  dependencies: [
    .package(path: "../BookishRecord"),
    .package(path: "../BookishCoding"),
    .package(path: "../BookishImporterNu"),
    .package(path: "../BookishDatastore"),
    .package(path: "../BookishRecordView"),
    .package(path: "../Application"),
    .package(path: "../Commands"),
  ],
  targets: [
    .target(
      name: "BookishApp",
      dependencies: [
        .product(name: "Application", package: "Application"),
        .product(name: "BookishRecord", package: "BookishRecord"),
        .product(name: "BookishCoding", package: "BookishCoding"),
        .product(name: "BookishImporter", package: "BookishImporterNu"),
        .product(name: "BookishImporterSamples", package: "BookishImporterNu"),
        .product(name: "BookishDatastore", package: "BookishDatastore"),
        .product(name: "BookishRecordView", package: "BookishRecordView"),
        .product(name: "Commands", package: "Commands"),
        .product(name: "CommandsUI", package: "Commands"),
      ]
    ),
    .testTarget(
      name: "BookishAppTests",
      dependencies: [
        "BookishApp",
        .product(name: "BookishCoding", package: "BookishCoding"),
        .product(name: "BookishRecord", package: "BookishRecord"),
        .product(name: "BookishImporterSamples", package: "BookishImporterNu"),
      ]
    ),
  ]
)

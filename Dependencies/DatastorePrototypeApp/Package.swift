// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "DatastorePrototypeApp",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "DatastorePrototypeApp",
      targets: ["DatastorePrototypeApp"]
    )
  ],
  dependencies: [
    .package(path: "../BookishRecord"),
    .package(path: "../BookishCoding"),
    .package(path: "../BookishImporterNu"),
    .package(path: "../BookishDatastore"),
    .package(path: "../BookishRecordView"),
  ],
  targets: [
    .target(
      name: "DatastorePrototypeApp",
      dependencies: [
        .product(name: "BookishRecord", package: "BookishRecord"),
        .product(name: "BookishCoding", package: "BookishCoding"),
        .product(name: "BookishImporterNu", package: "BookishImporterNu"),
        .product(name: "BookishDatastore", package: "BookishDatastore"),
        .product(name: "BookishRecordView", package: "BookishRecordView"),
      ]
    ),
    .testTarget(
      name: "DatastorePrototypeAppTests",
      dependencies: [
        "DatastorePrototypeApp",
        .product(name: "BookishCoding", package: "BookishCoding"),
        .product(name: "BookishRecord", package: "BookishRecord"),
      ]
    ),
  ]
)

// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishImporterNu",
  platforms: [
    .macOS(.v26), .iOS(.v26)
  ],
  products: [
    .library(
      name: "BookishImporter",
      targets: ["BookishImporter"]
    ),
    .library(
      name: "BookishImporterSamples",
      targets: ["BookishImporterSamples"]
    ),
  ],
  dependencies: [
    .package(path: "../BookishRecord"),
    .package(path: "../BookishCoding"),
    .package(path: "../BookishCleanupNu"),
  ],
  targets: [
    .target(
      name: "BookishImporter",
      dependencies: [
        .product(name: "BookishRecord", package: "BookishRecord"),
        .product(name: "BookishCoding", package: "BookishCoding"),
        .product(name: "BookishCleanup", package: "BookishCleanupNu"),
      ]
    ),
    .target(
      name: "BookishImporterSamples",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "BookishImporterNuTests",
      dependencies: [
        "BookishImporter",
        "BookishImporterSamples",
        .product(name: "BookishCoding", package: "BookishCoding"),
      ]
    ),
  ]
)

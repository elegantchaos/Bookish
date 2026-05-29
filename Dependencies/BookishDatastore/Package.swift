// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishDatastore",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "BookishDatastore",
      targets: ["BookishDatastore"]
    )
  ],
  targets: [
    .target(
      name: "BookishDatastore"
    ),
    .testTarget(
      name: "BookishDatastoreTests",
      dependencies: ["BookishDatastore"]
    ),
  ]
)

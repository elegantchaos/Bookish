// swift-tools-version:6.4

import PackageDescription

let package = Package(
  name: "BookishLookup",
  platforms: [
    .macOS(.v26), .iOS(.v26),
  ],
  products: [
    .library(
      name: "BookishLookup",
      targets: ["BookishLookup"]
    )
  ],
  dependencies: [
    .package(path: "../BookishRecord")
  ],
  targets: [
    .target(
      name: "BookishLookup",
      dependencies: ["BookishRecord"]
    ),
    .testTarget(
      name: "BookishLookupTests",
      dependencies: ["BookishLookup"]
    ),
  ]
)

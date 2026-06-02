// swift-tools-version:6.3

import PackageDescription

let package = Package(
  name: "BookishRecord",
  platforms: [
    .macOS(.v26)
  ],
  products: [
    .library(
      name: "BookishRecord",
      targets: ["BookishRecord"]
    )
  ],
  targets: [
    .target(
      name: "BookishRecord"
    ),
    .testTarget(
      name: "BookishRecordTests",
      dependencies: ["BookishRecord"]
    ),
  ]
)

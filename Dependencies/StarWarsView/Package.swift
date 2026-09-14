// swift-tools-version:6.4

import PackageDescription

let package = Package(
  name: "StarWarsView",
  platforms: [
    .macOS(.v26), .iOS(.v26)
  ],
  products: [
    .library(
      name: "StarWarsView",
      targets: ["StarWarsView"]
    )
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "StarWarsView",
      dependencies: [
      ]
    ),
    .testTarget(
      name: "StarWarsViewTests",
      dependencies: ["StarWarsView"]
    ),
  ]
)

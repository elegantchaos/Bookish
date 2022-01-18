// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "BookishCore",
    platforms: [
        .macOS(.v12), .iOS(.v15)
    ],
    products: [
        .library(
            name: "BookishCore",
            targets: ["BookishCore"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Bundles.git", from: "1.0.10"),
        .package(url: "https://github.com/elegantchaos/Coercion.git", from: "1.1.3"),
        .package(url: "https://github.com/elegantchaos/ISBN.git", from: "1.0.2"),
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.4.2"),
    ],
    
    targets: [
        .target(
            name: "BookishCore",
            dependencies: [
                "Bundles",
                "Coercion",
                "ISBN"
            ]
        ),
        
        .testTarget(
            name: "BookishCoreTests",
            dependencies: ["BookishCore", "XCTestExtensions"]
        ),
    ]
)

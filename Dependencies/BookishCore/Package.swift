// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "BookishCore",
    platforms: [
        .macOS(.v11), .iOS(.v14)
    ],
    products: [
        .library(
            name: "BookishCore",
            targets: ["BookishCore"]),
    ],
    
    dependencies: [
        .package(url: "https://github.com/elegantchaos/Coercion.git", from: "1.1.2"),
        .package(url: "https://github.com/elegantchaos/ISBN.git", from: "1.0.2"),
    ],
    
    targets: [
        .target(
            name: "BookishCore",
            dependencies: [
                "Coercion",
                "ISBN"
            ]
        ),
        
        .testTarget(
            name: "BookishCoreTests",
            dependencies: ["BookishCore"]
        ),
    ]
)

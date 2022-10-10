// swift-tools-version:5.7

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2022.
//  All code (c) 2022 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

let package = Package(
    name: "BookishApp",

    platforms: [
        .macCatalyst(.v16), .iOS(.v16), .tvOS(.v16), .macOS(.v12)
    ],

    products: [
        .library(
            name: "BookishApp",
            targets: ["BookishApp"]
        ),
    ],
    
    dependencies: [
        .package(path: "../BookishCleanup"),
        .package(path: "../BookishCore"),
        .package(path: "../BookishImporter"),
        .package(url: "https://github.com/elegantchaos/Bundles.git", from: "1.0.10"),
        .package(url: "https://github.com/elegantchaos/CaptureView.git", from: "1.0.3"),
        .package(url: "https://github.com/elegantchaos/JSONRepresentable.git", from: "1.0.1"),
        .package(url: "https://github.com/elegantchaos/KeyValueStore.git", from: "1.2.0"),
        .package(url: "https://github.com/elegantchaos/Labelled.git", from: "1.0.8"),
        .package(url: "https://github.com/elegantchaos/Logger.git", from: "1.8.1"),
        .package(url: "https://github.com/elegantchaos/NavigationPathExtensions.git", from: "1.0.0"),
        .package(url: "https://github.com/elegantchaos/SheetController.git", from: "1.0.3"),
        .package(url: "https://github.com/elegantchaos/SwiftUIExtensions.git", from: "1.3.8"),

        // testing support
        .package(url: "https://github.com/elegantchaos/XCTestExtensions.git", from: "1.4.2"),
        
        // tools
        .package(url: "https://github.com/elegantchaos/ActionBuilderPlugin.git", from: "1.0.7"),
        .package(url: "https://github.com/elegantchaos/SwiftFormatterPlugin.git", from: "1.0.3"),
    ],
    
    targets: [
        .target(
            name: "BookishApp",
            dependencies: [
                .product(name: "BookishCleanup", package: "BookishCleanup"),
                "BookishCore",
                .product(name: "BookishImporter", package: "BookishImporter"),
                .product(name: "BookishImporterSamples", package: "BookishImporter"),
                "Bundles",
                "CaptureView",
                "JSONRepresentable",
                "KeyValueStore",
                "Labelled",
                "NavigationPathExtensions",
                .product(name: "LoggerUI", package: "Logger"),
                "SheetController",
                "SwiftUIExtensions"
            ]
        ),
        
        .testTarget(
            name: "BookishAppTests",
            dependencies: [
                "BookishApp",
                "XCTestExtensions"
            ]
        ),
    ]
)

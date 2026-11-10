// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LlamaSwift",
    platforms: [
        .macOS(.v15),
        .iOS(.v17),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "LlamaSwift",
            targets: ["LlamaSwift"]
        ),
    ],
    targets: [
        .target(
            name: "LlamaSwift",
            dependencies: [
                .target(name: "llama-cpp")
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .binaryTarget(
            name: "llama-cpp",
            path: "llama.xcframework"
        ),
    ]
)

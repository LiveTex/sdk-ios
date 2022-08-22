// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LivetexCore",
    products: [
        .library(name: "LivetexCore", targets: ["LivetexCore"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "LivetexCore", dependencies: []),
        .testTarget(name: "LivetexCoreTests", dependencies: ["LivetexCore"]),
    ]
)

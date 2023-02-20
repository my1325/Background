// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Background",
    products: [
        .library(name: "MainRunloopObserver", targets: ["MainRunloopObserver"]),
        .library(name: "Background", targets: ["Background"]),
    ],
    targets: [
        .target(name: "MainRunloopObserver"),
        .target(name: "Background", dependencies: ["MainRunloopObserver"]),
    ]
)

// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MatrixRustComponentsSwiftExamples",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Walkthrough", targets: ["Walkthrough"])
    ],
    dependencies: [
        .package(path: "../"), // matrix-rust-components-swift
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.0")
    ],
    targets: [
        .executableTarget(name: "Walkthrough",
                          dependencies: [
                            .product(name: "MatrixRustSDK", package: "matrix-rust-components-swift"),
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "KeychainAccess", package: "KeychainAccess")
                          ]),
    ]
)

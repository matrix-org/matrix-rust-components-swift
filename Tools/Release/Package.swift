// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Release",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "release", targets: ["Release"])],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/element-hq/swift-command-line-tools.git", revision: "f9695015fff3c619172e5337266c46cfe5c327d7")
    ],
    targets: [
        .executableTarget(name: "Release", 
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "CommandLineTools", package: "swift-command-line-tools")
                          ])
    ]
)

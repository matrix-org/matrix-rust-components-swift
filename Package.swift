// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "5fbfbec9dd465f665a03f4cff24458755f5e42a8cc093f12f82828b34bb96faf"
let version = "v1.0.26-alpha"
let url = "https://github.com/matrix-org/matrix-rust-components-swift/releases/download/\(version)/MatrixSDKFFI.xcframework.zip"

let package = Package(
    name: "MatrixRustSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "MatrixRustSDK", targets: ["MatrixRustSDK"]),
    ],
    targets: [
        .binaryTarget(name: "MatrixSDKFFI", url: url, checksum: checksum),
        .target(name: "MatrixRustSDK", dependencies: [.target(name: "MatrixSDKFFI")])
    ]
)

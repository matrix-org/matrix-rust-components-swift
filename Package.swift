// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "6f75dc480063cf0cab70d47d307cb73358865552497488e5c6c55a1b95269dee"
let version = "v0.0.7-november23"
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

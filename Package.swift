// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "8d88fdc00db68bc6184748c3e08642b9cd4e55dbd7eed6c5da1ee789d18ef655"
let version = "v1.0.57-alpha"
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

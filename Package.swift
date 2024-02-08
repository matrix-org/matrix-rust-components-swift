// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "5102270eafbac7cc12bf8b568992aabe729284528315455259e44a523d57418b"
let version = "v1.1.38"
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

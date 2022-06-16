// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "af6d006e0735edb6dcb6e17bee1776eb8c140d532abc4153647c1cb761a9af5f"
let version = "v1.0.10-alpha"
let url = "https://github.com/matrix-org/matrix-rust-components-swift/releases/download/\(version)/MatrixSDKFFI.xcframework.zip"

let useLocalBinary = false
let binaryTarget: Target = useLocalBinary ? .binaryTarget(name: "MatrixSDKFFI", path: "MatrixSDKFFI.xcframework")
                                          : .binaryTarget(name: "MatrixSDKFFI", url: url, checksum: checksum)

let package = Package(
    name: "MatrixRustSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MatrixRustSDK",
            targets: ["MatrixRustSDK"]),
    ],
    targets: [
        binaryTarget,
        /*
         * A placeholder wrapper for our binaryTarget so that Xcode will ensure this is
         * downloaded/built before trying to use it in the build process
         * A bit hacky but necessary for now https://github.com/mozilla/application-services/issues/4422
         */
        .target(
            name: "MatrixSDKFFIWrapper",
            dependencies: [
                .target(name: "MatrixSDKFFI")
            ],
            path: "MatrixSDKFFIWrapper"
        ),
        .target(
            name: "MatrixRustSDK",
            dependencies: ["MatrixSDKFFIWrapper"]),
        .testTarget(
            name: "MatrixRustSDKTests",
            dependencies: ["MatrixRustSDK"]),
    ]
)

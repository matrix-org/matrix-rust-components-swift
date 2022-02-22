// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "10db0e90274ea87744494d85f01fc12c652cc06d0a7d7dd173f0d00251033820"
let version = "v1.0.1-alpha"
let url = "https://github.com/matrix-org/matrix-rust-components-swift/releases/download/\(version)/MatrixSDKFFI.xcframework.zip"

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
//        .binaryTarget(
//            name: "MatrixSDKFFI",
//            path: "MatrixSDKFFI.xcframework"),
        .binaryTarget(
            name: "MatrixSDKFFI",
            url: url,
            checksum: checksum),
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

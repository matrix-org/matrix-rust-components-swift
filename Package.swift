// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let checksum = "058bb3fb1b097d6d4f00782c3d75d315e53d9cdf1729453e596c79376b1a05e8"
let version = "v0.0.8-demo"
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
            name: "MatrixRustSDK",
            dependencies: [
                .target(name: "MatrixSDKFFI")
            ]
        ),
        .testTarget(
            name: "MatrixRustSDKTests",
            dependencies: ["MatrixRustSDK"]),
    ]
)

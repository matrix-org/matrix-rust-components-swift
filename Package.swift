// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let checksum = "c93d13be80d129dd029ad1aa9842c888a27ea02950a888059255a6bb87676c54"
let version = "v1.1.66"
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

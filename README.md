# Swift package for Matrix Rust components

This repository is a Swift Package for distributing releases of the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk). It provides the Swift source code packaged in a format understood by the Swift package manager, and depends on a pre-compiled binary release of the underlying Rust code published from [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk).

## Releasing

Whenever a new release of the underlying components is available, we need to tag a new release in this repo to make them available to Swift components. 
To do so we need to:
* running the `.xcframework` build script from `matrix-rust-sdk/apple`
* copy the generated `.swift` files to this repository under `Sources/MatrixRustComponentsSwift`
* update the tag version and checksum inside `Package.swift`
* create a new tag and upload the zipped version of the `.xcframework` to it's artefacts section

## Testing locally

The package can be added to an Xcode project from a local checkout and the binary target can be configured by toggling the `useLocalBinary` boolean. It might be necessary to manually add the resulting library to your project's `General/Frameworks, Libraries, and Embedded Content` for it to work.

## Requirements

To build the package you will need the following installed:
1. cargo + rustup https://www.rust-lang.org/tools/install
2. uniffi-bindgen `cargo install uniffi_bindgen --version x.x.x | --git https://github.com/mozilla/uniffi-rs --rev abc...` where the version or revision needs to match the one defined in the rust-sdk-ffi crate [Cargo.toml](https://github.com/matrix-org/matrix-rust-sdk/blob/main/bindings/matrix-sdk-ffi/Cargo.toml).
3. nightly toolchain and simulator targets for your desired platform. See the [release script](https://github.com/matrix-org/matrix-rust-sdk/blob/main/bindings/apple/build_xcframework.sh) for all possible options.
```
rustup toolchain install nightly
rustup default nightly
rustup target add aarch64-apple-ios --toolchain nightly
rustup target add aarch64-apple-darwin --toolchain nightly
rustup target add aarch64-apple-ios-sim --toolchain nightly
rustup target add x86_64-apple-ios --toolchain nightly
rustup target add x86_64-apple-darwin --toolchain nightly
```
4. matrix-rust-sdk cloned next to this repo `git clone https://github.com/matrix-org/matrix-rust-sdk`
5. When running the `debug_build_xcframework.sh` script, enable the `useLocalBinary` flag in `Package.swift`.

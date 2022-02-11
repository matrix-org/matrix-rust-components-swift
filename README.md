# Swift package for Matrix Rust components

This repository is a Swift Package for distributing releases of the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk). It provides the Swift source code packaged in a format understood by the Swift package manager, and depends on a pre-compiled binary release of the underlying Rust code published from [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk).

## Releasing

Whenever a new release of the underlying components is availble, we need to tag a new release in this repo to make them available to Swift components. 
To do so we need to:
* running the `.xcframework` build script from `matrix-rust-sdk/apple`
* copy the generated `.swift` files to this repository under `Sources/MatrixRustComponentsSwift`
* create a new tag and upload the zipped version of the `.xcframework` to it's artifacts section
* update the tag version inside `Package.swift`

## Testing locally

The package can be added to an Xcode project from a local checkout and the binary target can be configured with a local `path`. 
It might be necessary to manually add the resulting library to your project's `General/Frameworks, Libraries, and Embedded Content` for it to work.
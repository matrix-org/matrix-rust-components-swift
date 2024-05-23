# Swift package for Matrix Rust components

This repository is a Swift Package for distributing releases of the [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk). It provides the Swift source code packaged in a format understood by the Swift package manager, and depends on a pre-compiled binary release of the underlying Rust code published from [Matrix Rust SDK](https://github.com/matrix-org/matrix-rust-sdk).

## Usage

For more information about using the package, please read the [Getting Started](docs/Getting%20Started.md) guide.

## Releasing

Whenever a new release of the underlying components is available, we need to tag a new release in this repo to make them available to Swift components. 
This is done with the [release script](Tools/Release/README.md) found in the Tools directory. 

## Testing locally

As the package vendors a pre-built binary of the SDK, all local development is done via the SDK's repo instead of this one.

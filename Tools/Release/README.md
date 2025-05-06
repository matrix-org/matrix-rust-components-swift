# Scripts

## Release
Creates a Github release from a matrix-rust-sdk repository.

Usage:
```
swift run release    # will use a generated calver e.g. 25.12.31
```

For help (including how to customise the version): `swift run release --help`

## Requirements

To make the release you will need the following installed:
1. Set `api.github.com` in your .netrc file before using
2. cargo + rustup https://www.rust-lang.org/tools/install
3. matrix-rust-sdk cloned next to this repo `git clone https://github.com/matrix-org/matrix-rust-sdk`
4. Checkout the `main` branch of the SDK (or another custom branch to release from).
5. Any dependencies required to build the matrix-rust-sdk as mentioned in the [Apple platforms readme](https://github.com/matrix-org/matrix-rust-sdk/blob/main/bindings/apple/README.md).

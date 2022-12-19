# Scripts

## Release
Creates a Github release from a matrix-rust-sdk repository. Set `GITHUB_TOKEN` environment variable before using.

Usage:
```
python3 release.py --version v1.0.18-alpha
```

For help: `release.py -h`

## Requirements

To make the release you will need the following installed:
1. cargo + rustup https://www.rust-lang.org/tools/install
2. matrix-rust-sdk cloned next to this repo `git clone https://github.com/matrix-org/matrix-rust-sdk`
3. Any dependencies required to build the matrix-rust-sdk as mentioned in the [Apple platforms readme](https://github.com/matrix-org/matrix-rust-sdk/blob/main/bindings/apple/README.md).

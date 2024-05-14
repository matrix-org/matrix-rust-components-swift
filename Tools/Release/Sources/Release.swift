import ArgumentParser
import CommandLineTools
import Foundation

@main
struct Release: AsyncParsableCommand {
    @Option(help: "The version of the package that is being released.")
    var version: String
    
    @Flag(help: "Prevents the run from pushing anything to GitHub.")
    var localOnly = false
    
    var apiToken = (try? NetrcParser.parse(file: FileManager.default.homeDirectoryForCurrentUser.appending(component: ".netrc")))!
        .authorization(for: URL(string: "https://api.github.com")!)!
        .password
    
    var sourceRepo = Repository(owner: "matrix-org", name: "matrix-rust-sdk")
    var packageRepo = Repository(owner: "matrix-org", name: "matrix-rust-components-swift")
    
    var packageDirectory = URL(fileURLWithPath: #file)
        .deletingLastPathComponent() // Release.swift
        .deletingLastPathComponent() // Sources
        .deletingLastPathComponent() // Release
        .deletingLastPathComponent() // Tools
    lazy var buildDirectory = packageDirectory
        .deletingLastPathComponent() // matrix-rust-components-swift
        .appending(component: "matrix-rust-sdk")
    
    mutating func run() async throws {
        let package = Package(repository: packageRepo, directory: packageDirectory, apiToken: apiToken, urlSession: localOnly ? .releaseMock : .shared)
        Zsh.defaultDirectory = package.directory
        
        Log.info("Build directory: \(buildDirectory.path())")
        
        let product = try build()
        let (zipFileURL, checksum) = try package.zipBinary(with: product)
        
        try await updatePackage(package, with: product, checksum: checksum)
        try commitAndPush(with: product)
        try await package.makeRelease(with: product, uploading: zipFileURL)
    }
    
    mutating func build() throws -> BuildProduct {
        let commitHash = try Zsh.run(command: "git rev-parse HEAD", directory: buildDirectory)!.trimmingCharacters(in: .whitespacesAndNewlines)
        let branch = try Zsh.run(command: "git rev-parse --abbrev-ref HEAD", directory: buildDirectory)!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Log.info("Building \(branch) at \(commitHash)")
        
        // unset fixes an issue where swift compilation prevents building for targets other than macOS
        try Zsh.run(command: "unset SDKROOT && cargo xtask swift build-framework --release", directory: buildDirectory)
        
        return BuildProduct(sourceRepo: sourceRepo,
                            version: version,
                            commitHash: commitHash,
                            branch: branch,
                            directory: buildDirectory.appending(component: "bindings/apple/generated/"),
                            frameworkName: "MatrixSDKFFI.xcframework")
    }
    
    func updatePackage(_ package: Package, with product: BuildProduct, checksum: String) async throws {
        Log.info("Copying sources")
        let source = product.directory.appending(component: "swift", directoryHint: .isDirectory)
        let destination = package.directory.appending(component: "Sources/MatrixRustSDK", directoryHint: .isDirectory)
        try Zsh.run(command: "rsync -a --delete '\(source.path())' '\(destination.path())'")
        
        try await package.updateManifest(with: product, checksum: checksum)
    }
    
    func commitAndPush(with product: BuildProduct) throws {
        Log.info("Pushing changes")
        try Zsh.run(command: "git add Package.swift")
        try Zsh.run(command: "git add Sources")
        try Zsh.run(command: "git commit -m 'Bump to version \(version) (\(product.sourceRepo.name)/\(product.branch) \(product.commitHash))'")
        
        guard !localOnly else {
            Log.info("Skipping push for --local-only")
            return
        }
        
        try Zsh.run(command: "git push")
    }
}

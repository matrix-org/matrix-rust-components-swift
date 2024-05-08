import ArgumentParser
import CryptoKit
import Foundation

@main
struct Release: AsyncParsableCommand {
    
    @Option(help: "The version of the library that is being released.")
    var version: String
    
    var apiToken = (try? NetrcParser.parse(file: FileManager.default.homeDirectoryForCurrentUser.appending(component: ".netrc")))!
        .authorization(for: URL(string: "https://api.github.com")!)!
        .password
    
    var packageRepo = "matrix-org/matrix-rust-components-swift"
    var packageDirectory = URL(fileURLWithPath: #file)
        .deletingLastPathComponent() // Release.swift
        .deletingLastPathComponent() // Sources
        .deletingLastPathComponent() // Release
        .deletingLastPathComponent() // Tools
    
    lazy var buildDirectory = packageDirectory
        .deletingLastPathComponent() // matrix-rust-components-swift
        .appending(component: "matrix-rust-sdk")
    
    mutating func run() async throws {
        info("Build directory: \(buildDirectory.path())")
        
        let libraryDirectory = try buildLibrary()
        let (zipFileURL, checksum) = try zipBinary(at: libraryDirectory)
        
        try await updatePackage(from: libraryDirectory, checksum: checksum)
        let commitHash = try commitAndPush()
        try await makeRelease(at: commitHash, uploading: zipFileURL)
    }
    
    mutating func buildLibrary() throws -> URL {
        // unset fixes an issue where swift compilation prevents building for targets other than macOS X
        try run(command: "unset SDKROOT && cargo xtask swift build-framework --release", directory: buildDirectory)
        return buildDirectory.appending(component: "bindings/apple/generated/")
    }
    
    mutating func zipBinary(at libraryDirectory: URL) throws -> (URL, String) {
        let zipFileURL = packageDirectory.appending(component: "MatrixSDKFFI.xcframework.zip")
        if FileManager.default.fileExists(atPath: zipFileURL.path()) {
            info("Deleting old framework")
            try FileManager.default.removeItem(at: zipFileURL)
        }

        info("Zipping framework")
        try run(command: "zip -r '\(zipFileURL.path())' MatrixSDKFFI.xcframework", directory: libraryDirectory)
        let checksum = try checksum(for: zipFileURL)
        info("Checksum: \(checksum)")
        
        return (zipFileURL, checksum)
    }
    
    func updatePackage(from libraryDirectory: URL, checksum: String) async throws {
        info("Copying sources")
        let source = libraryDirectory.appending(component: "swift", directoryHint: .isDirectory)
        let destination = packageDirectory.appending(component: "Sources/MatrixRustSDK", directoryHint: .isDirectory)
        try run(command: "rsync -a --delete '\(source.path())' '\(destination.path())'")
        
        info("Updating manifest")
        let manifestURL = packageDirectory.appending(component: "Package.swift")
        var updatedManifest = ""
        
        #warning("Strips empty lines")
        for try await line in manifestURL.lines {
            if line.starts(with: "let version = ") {
                updatedManifest.append("let version = \"\(version)\"")
            } else if line.starts(with: "let checksum = ") {
                updatedManifest.append("let checksum = \"\(checksum)\"")
            } else {
                updatedManifest.append(line)
            }
            updatedManifest.append("\n")
        }
        
        try updatedManifest.write(to: manifestURL, atomically: true, encoding: .utf8)
    }
    
    mutating func commitAndPush() throws -> String {
        let commitHash = try run(command: "git rev-parse HEAD", directory: buildDirectory)!.trimmingCharacters(in: .whitespacesAndNewlines)
        let branch = try run(command: "git rev-parse --abbrev-ref HEAD", directory: buildDirectory)!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        info("Pushing changes")
        try run(command: "git add Package.swift")
        try run(command: "git add Sources")
        try run(command: "git commit -m 'Bump to version \(version) (matrix-rust-sdk/\(branch) \(commitHash))'")
        try run(command: "git push")
        
        return commitHash
    }
    
    func makeRelease(at commitHash: String, uploading zipFileURL: URL) async throws {
        info("Making release")
        let url = URL(string: "https://api.github.com/repos")!
            .appending(path: packageRepo)
            .appending(component: "releases")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content")
        
        let body = GitHubReleaseRequest(tagName: version,
                                        targetCommitish: "main",
                                        name: version,
                                        body: "https://github.com/matrix-org/matrix-rust-sdk/tree/\(commitHash)",
                                        draft: false,
                                        prerelease: false,
                                        generateReleaseNotes: false,
                                        makeLatest: "true")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let bodyData = try encoder.encode(body)
        request.httpBody = bodyData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        
        info("Release created \(release.htmlURL)")
        
        try await uploadFramework(at: zipFileURL, to: release.uploadURL)
    }
    
    func uploadFramework(at fileURL: URL, to uploadURL: URL) async throws {
        info("Uploading framework")
        
        var uploadComponents = URLComponents(url: uploadURL, resolvingAgainstBaseURL: false)!
        uploadComponents.queryItems = [URLQueryItem(name: "name", value: fileURL.lastPathComponent)]
        
        var request = URLRequest(url: uploadComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/zip", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.upload(for: request, fromFile: fileURL)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReleaseError.httpResponse(-1)
        }
        guard httpResponse.statusCode == 201 else {
            throw ReleaseError.httpResponse(httpResponse.statusCode)
        }
        
        let upload = try JSONDecoder().decode(GitHubUploadResponse.self, from: data)
        info("Upload finished \(upload.browserDownloadURL)")
    }
    
    // MARK: Helpers
    
    private func info(_ message: String) {
        print("🚀 \(message)")
    }
    
    @discardableResult
    private func run(command: String, directory: URL? = nil) throws -> String? {
        let process = Process()
        let outputPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-cu", command]
        process.currentDirectoryURL = directory ?? packageDirectory
        process.standardOutput = outputPipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw ReleaseError.commandFailure(command: command, directory: directory ?? packageDirectory)
        }
        
        guard let outputData = try outputPipe.fileHandleForReading.readToEnd() else { return nil }
        return String(data: outputData, encoding: .utf8)
    }
    
    private func checksum(for fileURL: URL) throws -> String {
        var hasher = SHA256()
        let handle = try FileHandle(forReadingFrom: fileURL)
        
        while let bytes = try handle.read(upToCount: SHA256.blockByteCount) {
            hasher.update(data: bytes)
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

enum ReleaseError: Error {
    case commandFailure(command: String, directory: URL)
    case httpResponse(Int)
}

// MARK: - GitHub Release https://docs.github.com/en/rest/releases/releases#create-a-release

struct GitHubReleaseRequest: Encodable {
    let tagName: String
    let targetCommitish: String
    let name: String
    let body: String
    let draft: Bool
    let prerelease: Bool
    let generateReleaseNotes: Bool
    let makeLatest: String
}

struct GitHubRelease: Decodable {
    let htmlURL: URL
    let uploadURLString: String // Decode as a string to avoid URL percent encoding.
    
    var uploadURL: URL {
        URL(string: String(uploadURLString.split(separator: "{")[0]))!
    }
    
    enum CodingKeys: String, CodingKey {
        case htmlURL = "html_url"
        case uploadURLString = "upload_url"
    }
}

struct GitHubUploadResponse: Decodable {
    let browserDownloadURL: String
    
    enum CodingKeys: String, CodingKey {
        case browserDownloadURL = "browser_download_url"
    }
}

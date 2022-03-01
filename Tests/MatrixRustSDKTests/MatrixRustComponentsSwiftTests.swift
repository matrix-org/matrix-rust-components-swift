import XCTest
@testable import MatrixRustSDK

final class MatrixRustComponentsSwiftTests: XCTestCase {
    func testExample() throws {
        do {
            let client = try loginNewClient(basePath: "", username: "", password: "")
            let displayName = try client.displayName()
            print("Display name: \(displayName)")
        } catch ClientError.Generic(let msg) {
            print("Failed with message \(msg)")
        } catch {
            fatalError()
        }
    }
}

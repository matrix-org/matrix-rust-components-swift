# Getting Started

The following instructions give a brief overview of using the Matrix Rust SDK from Swift. You can find more information about the API by browsing the [FFI crate](https://github.com/matrix-org/matrix-rust-sdk/tree/main/bindings/matrix-sdk-ffi/src) in the SDK's repository. In its current state, many of the calls to the SDK will block the thread that they're called on. You can determine this by looking for functions that use `RUNTIME.block_on` in their implementation. This is temporary and will be addressed in the future via [async support in Uniffi](https://github.com/mozilla/uniffi-rs/pull/1409).

Please note: The Swift components for the Rust SDK are unstable meaning that the API could change at any point.


### Project setup

Add https://github.com/matrix-org/matrix-rust-components-swift to your project as a Swift package.

### Usage

First we need to authenticate the user.

```swift
import MatrixRustSDK

// Create an authentication service to streamline the login process.
let service = AuthenticationService(basePath: URL.applicationSupportDirectory.path(), passphrase: nil)

// Configure the service for a particular homeserver.
// Note that we can pass a server name (the second part of a Matrix user ID) instead of the direct URL.
// This allows the SDK to discover the homeserver's well-known configuration for OIDC and Sliding Sync support.
try service.configureHomeserver(serverName: "matrix.org")

// Login through the service which creates a client.
let client = try service.login(username: "alice", password: "secret", initialDeviceName: nil, deviceId: nil)

let session = try client.session()
// Store the session in the keychain.
```

Or, if the user has previously authenticated we can restore their session instead.

```swift
// Get the session from the keychain.
let session = …

// Build a client for the homeserver.
let client = try ClientBuilder()
    .basePath(path: URL.applicationSupportDirectory.path())
    .homeserverUrl(url: session.homeserverUrl)
    .build()

// Restore the client using the session.
try client.restoreSession(session: session)
```

Next we need to start the client and listen for updates. The following code does so using syncv2.

```swift
class ClientListener: ClientDelegate {
    /// The user's list of rooms.
    var rooms = [Room]()
    
    func didReceiveSyncUpdate() {
        // Update the user's room list on each sync response.
        self.rooms = client.rooms()
    }
    
    func didReceiveAuthError(isSoftLogout: Bool) {
        // Ask the user to reauthenticate.
    }
    
    func didUpdateRestoreToken() {
        let session = try? client.session()
        // Update the session in the keychain.
    }
}

// Listen to updates from the client.
let listener = ClientListener()
client.setDelegate(delegate: listener)

// Start the client using syncv2.
client.startSync(timelineLimit: 20)
```

Finally we can send messages into a room (with built in support for markdown).

```swift
// Create the message content from a markdown string.
let message = messageEventContentFromMarkdown(md: "Hello, World!")

// Send the message content to the first room in the list.
try listener.rooms.first?.send(msg: message, txnId: UUID().uuidString)
```


# Getting Started

The following instructions give a brief overview of using the Matrix Rust SDK from Swift. You can find more information about the API by browsing the [FFI crate](https://github.com/matrix-org/matrix-rust-sdk/tree/main/bindings/matrix-sdk-ffi/src) in the SDK's repository. In its current state, many of the calls to the SDK will block the thread that they're called on. You can determine this by looking for functions that use `RUNTIME.block_on` in their implementation. This is temporary and will be addressed in the future via [async support in Uniffi](https://github.com/mozilla/uniffi-rs/pull/1409).

Please note: The Swift components for the Rust SDK are unstable meaning that the API could change at any point.


### Project setup

Add https://github.com/matrix-org/matrix-rust-components-swift to your project as a Swift package.

### Usage

First we need to authenticate the user.

```swift
import MatrixRustSDK

// Create a client for a particular homeserver.
// Note that we can pass a server name (the second part of a Matrix user ID) instead of the direct URL.
// This allows the SDK to discover the homeserver's well-known configuration for Sliding Sync support.
let client = try await ClientBuilder()
    .serverNameOrHomeserverUrl(serverNameOrUrl: "matrix.org")
    .sessionPaths(dataPath: URL.applicationSupportDirectory.path(percentEncoded: false),
                  cachePath: URL.cachesDirectory.path(percentEncoded: false))
    .slidingSyncVersionBuilder(versionBuilder: .discoverNative)
    .build()

// Login using password authentication.
try await client.login(username: "alice", password: "secret", initialDeviceName: nil, deviceId: nil)

let session = try client.session()
// Store the session in the keychain.
```

Or, if the user has previously authenticated we can restore their session instead.

```swift
// Get the session from the keychain.
let session = …

// Build a client for the homeserver.
let client = try await ClientBuilder()
    .sessionPaths(dataPath: URL.applicationSupportDirectory.path(percentEncoded: false),
                  cachePath: URL.cachesDirectory.path(percentEncoded: false))
    .homeserverUrl(url: session.homeserverUrl)
    .build()

// Restore the client using the session.
try await client.restoreSession(session: session)
```

Next we need to start the sync loop and listen for room updates.

```swift
class AllRoomsListener: RoomListEntriesListener {
    /// The user's list of rooms.
    var rooms: [RoomListItem] = []
    
    func onUpdate(roomEntriesUpdate: [MatrixRustSDK.RoomListEntriesUpdate]) {
        // Update the user's room list on each update.
        for update in roomEntriesUpdate {
            switch update {
            case .reset(values: let values):
                rooms = values
            default:
                break // Handle all the other cases accordingly.
            }
        }
    }
}

// Create a sync service which controls the sync loop.
let syncService = try await client.syncService().finish()

// Listen to room list updates.
let listener = AllRoomsListener()
let roomListService = syncService.roomListService()
let handle = try await roomListService.allRooms().entriesWithDynamicAdapters(pageSize: 100, listener: listener)

// Start the sync loop.
await syncService.start()
```

When we're ready to display the events from a room we use the timeline API.

```swift
class TimelineItemListener: TimelineListener {
    /// The loaded items for this room's timeline
    var timelineItems: [TimelineItem] = []
    
    func onUpdate(diff: [TimelineDiff]) {
        // Update the timeline items on each update.
        for update in diff {
            switch update.change() {
            case .reset:
                timelineItems = update.reset()!
            default:
                break // Handle all the other cases accordingly.
            }
        }
    }
}

// Fetch the room from the listener and initialise it's timeline.
let room = listener.rooms.first!
if !room.isTimelineInitialized() {
    try await room.initTimeline(eventTypeFilter: nil, internalIdPrefix: nil)
}
let timeline = try await room.fullRoom().timeline()

// Listen to timeline item updates.
let timelineItemsListener = TimelineItemListener()
let timelineHandle = await timeline.addListener(listener: timelineItemsListener)

// Wait for the items array to be updated…

// Get the event contents from an item.
let timelineItem = timelineItemsListener.timelineItems.last!
if let messageEvent = timelineItem.asEvent()?.content().asMessage() {
    print(messageEvent)
}
```

Finally we can send messages into the room (with built in support for markdown).

```swift
// Create the message content from a markdown string.
let message = messageEventContentFromMarkdown(md: "Hello, World!")

// Send the message content via the room's timeline (so that we show a local echo).
_ = try await timeline.send(msg: message)
```

import ArgumentParser
import Foundation
import MatrixRustSDK
import KeychainAccess

class Walkthrough {
    // MARK: - Step 1
    // Authenticate the user.
    
    var client: Client!
    
    func step1Login() async throws -> WalkthroughUser {
        let storeID = UUID().uuidString
        
        // Create a client for a particular homeserver.
        // Note that we can pass a server name (the second part of a Matrix user ID) instead of the direct URL.
        // This allows the SDK to discover the homeserver's well-known configuration for Sliding Sync support.
        let client = try await ClientBuilder()
            .serverNameOrHomeserverUrl(serverNameOrUrl: "matrix.org")
            .sessionPaths(dataPath: URL.sessionData(for: storeID).path(percentEncoded: false),
                          cachePath: URL.sessionCaches(for: storeID).path(percentEncoded: false))
            .slidingSyncVersionBuilder(versionBuilder: .discoverNative)
            .build()
        
        // Login using password authentication.
        try await client.login(username: "alice", password: "secret", initialDeviceName: nil, deviceId: nil)
        
        self.client = client
        
        // This data should be stored securely in the keychain.
        return try WalkthroughUser(session: client.session(), storeID: storeID)
    }
    
    // Or, if the user has previously authenticated we can restore their session instead.
    
    func step1Restore(_ walkthroughUser: WalkthroughUser) async throws {
        let session = walkthroughUser.session
        let sessionID = walkthroughUser.storeID
        
        // Build a client for the homeserver.
        let client = try await ClientBuilder()
            .sessionPaths(dataPath: URL.sessionData(for: sessionID).path(percentEncoded: false),
                          cachePath: URL.sessionCaches(for: sessionID).path(percentEncoded: false))
            .homeserverUrl(url: session.homeserverUrl)
            .build()
        
        // Restore the client using the session.
        try await client.restoreSession(session: session)
        
        self.client = client
    }
    
    // MARK: - Step 2
    // Build the room list.
    
    class AllRoomsListener: RoomListEntriesListener {
        /// The user's list of rooms.
        var rooms: [Room] = []
        
        func onUpdate(roomEntriesUpdate: [RoomListEntriesUpdate]) {
            // Update the user's room list on each update.
            for update in roomEntriesUpdate {
                switch update {
                case .append(let values):
                    rooms.append(contentsOf: values)
                case .clear:
                    rooms.removeAll()
                case .pushFront(let room):
                    rooms.insert(room, at: 0)
                case .pushBack(let room):
                    rooms.append(room)
                case .popFront:
                    rooms.removeFirst()
                case .popBack:
                    rooms.removeLast()
                case .insert(let index, let room):
                    rooms.insert(room, at: Int(index))
                case .set(let index, let room):
                    rooms[Int(index)] = room
                case .remove(let index):
                    rooms.remove(at: Int(index))
                case .truncate(let length):
                    rooms.removeSubrange(Int(length)..<rooms.count)
                case .reset(values: let values):
                    rooms = values
                }
            }
        }
    }
    
    var syncService: SyncService!
    var roomListService: RoomListService!
    var allRoomsListener: AllRoomsListener!
    var roomListEntriesHandle: RoomListEntriesWithDynamicAdaptersResult!
    
    func step2StartSync() async throws {
        // Create a sync service which controls the sync loop.
        syncService = try await client.syncService().finish()
        
        // Listen to room list updates.
        allRoomsListener = AllRoomsListener()
        roomListService = syncService.roomListService()
        roomListEntriesHandle = try await roomListService.allRooms().entriesWithDynamicAdapters(pageSize: 100, listener: allRoomsListener)
        _ = roomListEntriesHandle.controller().setFilter(kind: .all(filters: []))
        
        // Start the sync loop.
        await syncService.start()
    }
    
    // MARK: - Step 3
    // Create a timeline.
    
    class TimelineItemListener: TimelineListener {
        /// The loaded items for this room's timeline
        var timelineItems: [TimelineItem] = []
        
        func onUpdate(diff: [TimelineDiff]) {
            // Update the timeline items on each update.
            for update in diff {
                switch update {
                case .append(let values):
                    timelineItems.append(contentsOf: values)
                case .clear:
                    timelineItems.removeAll()
                case .pushFront(let room):
                    timelineItems.insert(room, at: 0)
                case .pushBack(let room):
                    timelineItems.append(room)
                case .popFront:
                    timelineItems.removeFirst()
                case .popBack:
                    timelineItems.removeLast()
                case .insert(let index, let room):
                    timelineItems.insert(room, at: Int(index))
                case .set(let index, let room):
                    timelineItems[Int(index)] = room
                case .remove(let index):
                    timelineItems.remove(at: Int(index))
                case .truncate(let length):
                    timelineItems.removeSubrange(Int(length)..<timelineItems.count)
                case .reset(values: let values):
                    timelineItems = values
                }
            }
        }
    }
    
    var timeline: Timeline!
    var timelineItemsListener: TimelineItemListener!
    var timelineHandle: TaskHandle!
    
    func step3LoadRoomTimeline() async throws {
        let roomID = "!someroomid:matrix.org"
        
        // Wait for the rooms array to contain the desired room…
        while !allRoomsListener.rooms.contains(where: { $0.id() == roomID }) {
            try await Task.sleep(for: .milliseconds(250))
        }
        
        // Fetch the room from the listener and initialise it's timeline.
        let room = allRoomsListener.rooms.first { $0.id() == roomID }!
        timeline = try await room.timeline()
        
        // Listen to timeline item updates.
        timelineItemsListener = TimelineItemListener()
        timelineHandle = await timeline.addListener(listener: timelineItemsListener)
        
        // Wait for the items array to be updated…
        while timelineItemsListener.timelineItems.isEmpty {
            try await Task.sleep(for: .milliseconds(250))
        }
        
        // Get the event contents from an item.
        let timelineItem = timelineItemsListener.timelineItems.last!
        if case let .msgLike(content: messageEvent) = timelineItem.asEvent()?.content,
           case let .message(content: messageContent) = messageEvent.kind {
            print(messageContent.body)
        }
    }
    
    // MARK: - Step 4
    // Sending events.
    
    var sendHandle: SendHandle?
    
    func step4SendMessage() async throws {
        // Create the message content from a markdown string.
        let message = messageEventContentFromMarkdown(md: "Hello, World!")
        
        // Send the message content via the room's timeline (so that we show a local echo).
        sendHandle = try await timeline.send(msg: message)
    }
}

// MARK: - @main

let applicationID = "org.matrix.swift.walkthrough"
let keychainSessionKey = "WalkthroughUser"

@main
struct WalkthroughCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "A basic example of using Matrix Rust SDK in Swift.")
    
    func run() async throws {
        let walkthrough = Walkthrough()
        
        if let walkthroughUser = try loadUserFromKeychain() {
            try await walkthrough.step1Restore(walkthroughUser)
        } else {
            let walkthroughUser = try await walkthrough.step1Login()
            try saveUserToKeychain(walkthroughUser)
        }
        
        try await walkthrough.step2StartSync()
        try await walkthrough.step3LoadRoomTimeline()
        try await walkthrough.step4SendMessage()
        
        // Don't exit immediately otherwise the message won't be sent (the await only suspends until the event is queued).
        _ = readLine()
    }
    
    func saveUserToKeychain(_ walkthroughUser: WalkthroughUser) throws {
        let keychainData = try JSONEncoder().encode(walkthroughUser)
        let keychain = Keychain(service: applicationID)
        try keychain.set(keychainData, key: keychainSessionKey)
    }
    
    func loadUserFromKeychain() throws -> WalkthroughUser? {
        let keychain = Keychain(service: applicationID)
        guard let keychainData = try keychain.getData(keychainSessionKey) else { return nil }
        return try JSONDecoder().decode(WalkthroughUser.self, from: keychainData)
    }
    
    private func reset() throws {
        if let walkthroughUser = try loadUserFromKeychain() {
            try? FileManager.default.removeItem(at: .sessionData(for: walkthroughUser.storeID))
            try? FileManager.default.removeItem(at: .sessionCaches(for: walkthroughUser.storeID))
            let keychain = Keychain(service: applicationID)
            try keychain.removeAll()
        }
    }
}

struct WalkthroughUser: Codable {
    let accessToken: String
    let refreshToken: String?
    let userID: String
    let deviceID: String
    let homeserverURL: String
    let oidcData: String?
    let storeID: String
    
    init(session: Session, storeID: String) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.userID = session.userId
        self.deviceID = session.deviceId
        self.homeserverURL = session.homeserverUrl
        self.oidcData = session.oidcData
        self.storeID = storeID
    }
    
    var session: Session {
        Session(accessToken: accessToken,
                refreshToken: refreshToken,
                userId: userID,
                deviceId: deviceID,
                homeserverUrl: homeserverURL,
                oidcData: oidcData,
                slidingSyncVersion: .native)
        
    }
}

extension URL {
    static func sessionData(for sessionID: String) -> URL {
        applicationSupportDirectory
            .appending(component: applicationID)
            .appending(component: sessionID)
    }
    
    static func sessionCaches(for sessionID: String) -> URL {
        cachesDirectory
            .appending(component: applicationID)
            .appending(component: sessionID)
    }
}

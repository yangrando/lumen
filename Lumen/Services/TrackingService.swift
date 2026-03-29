import Foundation
import SwiftUI
import CryptoKit

enum ReelTrackingEventName: String, Codable {
    case viewed = "reel.viewed"
    case translationOpened = "reel.translation_opened"
    case audioPlayed = "reel.audio_played"
    case aiHelpOpened = "reel.ai_help_opened"
    case aiHelpSubmitted = "reel.ai_help_submitted"
    case saved = "reel.saved"
    case understoodMarked = "reel.understood_marked"
    case speakingStarted = "reel.speaking_started"
    case speakingCompleted = "reel.speaking_completed"
    case timeSpent = "reel.time_spent"
}

enum StudySessionType: String, Codable, CaseIterable {
    case feed
    case review
    case speaking
}

enum StudySessionState: String, Codable {
    case started
    case heartbeat
    case ended
}

enum TrackingMetadataValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

typealias TrackingMetadata = [String: TrackingMetadataValue]

private struct QueuedTrackingEvent: Codable, Sendable {
    let clientEventID: String
    let eventName: ReelTrackingEventName
    let reelID: String?
    let clientSessionID: String?
    let eventTimestampMS: Int64
    let durationMS: Int?
    let metadata: TrackingMetadata

    enum CodingKeys: String, CodingKey {
        case clientEventID = "client_event_id"
        case eventName = "event_name"
        case reelID = "reel_id"
        case clientSessionID = "client_session_id"
        case eventTimestampMS = "event_timestamp_ms"
        case durationMS = "duration_ms"
        case metadata
    }
}

private struct QueuedSessionUpdate: Codable, Sendable {
    let clientSessionID: String
    let sessionType: StudySessionType
    let state: StudySessionState
    let timestampMS: Int64
    let metadata: TrackingMetadata

    enum CodingKeys: String, CodingKey {
        case clientSessionID = "client_session_id"
        case sessionType = "session_type"
        case state
        case timestampMS = "timestamp_ms"
        case metadata
    }
}

private struct ActiveStudySession: Codable, Sendable {
    let clientSessionID: String
    let sessionType: StudySessionType
    let startedAtMS: Int64
    var lastActivityAtMS: Int64
    var lastHeartbeatAtMS: Int64?
    var metadata: TrackingMetadata
}

private struct TrackingQueueSnapshot: Codable, Sendable {
    var ownerUserID: String?
    var deviceID: String
    var pendingEvents: [QueuedTrackingEvent]
    var pendingSessionUpdates: [QueuedSessionUpdate]
    var activeSessions: [String: ActiveStudySession]
}

private struct TrackingBatchRequestPayload: Codable {
    let events: [QueuedTrackingEvent]
    let sessionUpdates: [QueuedSessionUpdate]
    let sentAtMS: Int64
    let deviceID: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case events
        case sessionUpdates = "session_updates"
        case sentAtMS = "sent_at_ms"
        case deviceID = "device_id"
        case appVersion = "app_version"
    }
}

private struct TrackingBatchResponse: Codable {
    let status: String
    let acceptedEventCount: Int
    let duplicateEventCount: Int
    let appliedSessionUpdateCount: Int
    let serverTimestampMS: Int64

    enum CodingKeys: String, CodingKey {
        case status
        case acceptedEventCount = "accepted_event_count"
        case duplicateEventCount = "duplicate_event_count"
        case appliedSessionUpdateCount = "applied_session_update_count"
        case serverTimestampMS = "server_timestamp_ms"
    }
}

actor TrackingService {
    static let shared = TrackingService()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let batchEventLimit = 100
    private let batchSessionLimit = 30
    private let heartbeatIntervalMS: Int64 = 30_000

    private var snapshot: TrackingQueueSnapshot
    private var flushTask: Task<Void, Never>?
    private var retryAttempt = 0
    private var isFlushing = false

    private init() {
        self.snapshot = TrackingQueueSnapshot(
            ownerUserID: nil,
            deviceID: Self.loadDeviceID(),
            pendingEvents: [],
            pendingSessionUpdates: [],
            activeSessions: [:]
        )
        loadSnapshot()
    }

    func track(
        event: ReelTrackingEventName,
        reelID: String? = nil,
        sessionType: StudySessionType? = nil,
        durationMS: Int? = nil,
        metadata: TrackingMetadata = [:]
    ) async {
        guard let userID = await currentUserID() else { return }
        ensureOwnerUser(userID)

        let payload = QueuedTrackingEvent(
            clientEventID: UUID().uuidString.lowercased(),
            eventName: event,
            reelID: reelID,
            clientSessionID: sessionType.flatMap { snapshot.activeSessions[$0.rawValue]?.clientSessionID },
            eventTimestampMS: Self.nowMS(),
            durationMS: durationMS,
            metadata: metadata
        )

        snapshot.pendingEvents.append(payload)
        persistSnapshot()
        scheduleFlush()
    }

    func startSession(_ type: StudySessionType, metadata: TrackingMetadata = [:]) async -> String? {
        guard let userID = await currentUserID() else { return nil }
        ensureOwnerUser(userID)

        if let existing = snapshot.activeSessions[type.rawValue] {
            return existing.clientSessionID
        }

        let now = Self.nowMS()
        let session = ActiveStudySession(
            clientSessionID: UUID().uuidString.lowercased(),
            sessionType: type,
            startedAtMS: now,
            lastActivityAtMS: now,
            lastHeartbeatAtMS: nil,
            metadata: metadata
        )
        snapshot.activeSessions[type.rawValue] = session
        snapshot.pendingSessionUpdates.append(
            QueuedSessionUpdate(
                clientSessionID: session.clientSessionID,
                sessionType: type,
                state: .started,
                timestampMS: now,
                metadata: metadata
            )
        )
        persistSnapshot()
        scheduleFlush()
        return session.clientSessionID
    }

    func heartbeatSession(_ type: StudySessionType, metadata: TrackingMetadata = [:], force: Bool = false) async {
        guard var session = snapshot.activeSessions[type.rawValue] else { return }
        let now = Self.nowMS()
        if !force, let lastHeartbeat = session.lastHeartbeatAtMS, now - lastHeartbeat < heartbeatIntervalMS {
            return
        }

        session.lastActivityAtMS = now
        session.lastHeartbeatAtMS = now
        session.metadata.merge(metadata) { _, new in new }
        snapshot.activeSessions[type.rawValue] = session
        snapshot.pendingSessionUpdates.append(
            QueuedSessionUpdate(
                clientSessionID: session.clientSessionID,
                sessionType: type,
                state: .heartbeat,
                timestampMS: now,
                metadata: metadata
            )
        )
        persistSnapshot()
        scheduleFlush()
    }

    func endSession(_ type: StudySessionType, metadata: TrackingMetadata = [:]) async {
        guard var session = snapshot.activeSessions.removeValue(forKey: type.rawValue) else { return }
        let now = Self.nowMS()
        session.lastActivityAtMS = now
        session.metadata.merge(metadata) { _, new in new }
        snapshot.pendingSessionUpdates.append(
            QueuedSessionUpdate(
                clientSessionID: session.clientSessionID,
                sessionType: type,
                state: .ended,
                timestampMS: now,
                metadata: metadata
            )
        )
        persistSnapshot()
        scheduleFlush()
    }

    func activeSessionID(for type: StudySessionType) -> String? {
        snapshot.activeSessions[type.rawValue]?.clientSessionID
    }

    func flushIfNeeded(force: Bool = false) async {
        if force {
            flushTask?.cancel()
            flushTask = nil
        }
        await flushPending(force: force)
    }

    func handleScenePhaseChange(_ phase: ScenePhase) async {
        switch phase {
        case .active:
            await flushIfNeeded(force: true)
        case .background:
            let metadata: TrackingMetadata = ["reason": .string("app_background")]
            for type in StudySessionType.allCases {
                await endSession(type, metadata: metadata)
            }
            await flushIfNeeded(force: true)
        default:
            break
        }
    }

    func handleLogout() async {
        snapshot.ownerUserID = nil
        snapshot.pendingEvents.removeAll()
        snapshot.pendingSessionUpdates.removeAll()
        snapshot.activeSessions.removeAll()
        persistSnapshot()
    }

    private func scheduleFlush() {
        flushTask?.cancel()
        let delaySeconds = retryAttempt == 0 ? 0.0 : min(pow(2.0, Double(retryAttempt)), 60.0)
        let delayNS = UInt64(delaySeconds * 1_000_000_000)
        flushTask = Task {
            if delayNS > 0 {
                try? await Task.sleep(nanoseconds: delayNS)
            }
            await flushPending(force: false)
        }
    }

    private func flushPending(force: Bool) async {
        guard !isFlushing else { return }
        guard !snapshot.pendingEvents.isEmpty || !snapshot.pendingSessionUpdates.isEmpty else { return }
        guard let request = await makeRequestPayload() else { return }

        isFlushing = true
        defer { isFlushing = false }

        do {
            let response = try await send(request: request.payload, accessToken: request.accessToken)
            if response.status == "ok" {
                let eventsToRemove = min(request.eventCount, snapshot.pendingEvents.count)
                let sessionsToRemove = min(request.sessionCount, snapshot.pendingSessionUpdates.count)
                if eventsToRemove > 0 {
                    snapshot.pendingEvents.removeFirst(eventsToRemove)
                }
                if sessionsToRemove > 0 {
                    snapshot.pendingSessionUpdates.removeFirst(sessionsToRemove)
                }
                retryAttempt = 0
                persistSnapshot()
                if force, (!snapshot.pendingEvents.isEmpty || !snapshot.pendingSessionUpdates.isEmpty) {
                    await flushPending(force: true)
                }
            }
        } catch {
            retryAttempt = min(retryAttempt + 1, 6)
            persistSnapshot()
            scheduleFlush()
        }
    }

    private func makeRequestPayload() async -> (payload: TrackingBatchRequestPayload, accessToken: String, eventCount: Int, sessionCount: Int)? {
        guard let accessToken = await currentAccessToken(), !accessToken.isEmpty else { return nil }
        guard let userID = await currentUserID() else { return nil }
        ensureOwnerUser(userID)

        let events = Array(snapshot.pendingEvents.prefix(batchEventLimit))
        let sessions = Array(snapshot.pendingSessionUpdates.prefix(batchSessionLimit))
        guard !events.isEmpty || !sessions.isEmpty else { return nil }

        return (
            TrackingBatchRequestPayload(
                events: events,
                sessionUpdates: sessions,
                sentAtMS: Self.nowMS(),
                deviceID: snapshot.deviceID,
                appVersion: Self.appVersion
            ),
            accessToken,
            events.count,
            sessions.count
        )
    }

    private func send(request payload: TrackingBatchRequestPayload, accessToken: String) async throws -> TrackingBatchResponse {
        guard let endpoint = Self.apiBaseURL?.appendingPathComponent("tracking").appendingPathComponent("batch") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(TrackingBatchResponse.self, from: data)
    }

    private func ensureOwnerUser(_ userID: String) {
        if snapshot.ownerUserID == userID {
            return
        }
        snapshot.ownerUserID = userID
        snapshot.pendingEvents.removeAll()
        snapshot.pendingSessionUpdates.removeAll()
        snapshot.activeSessions.removeAll()
        persistSnapshot()
    }

    private func persistSnapshot() {
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: Self.snapshotURL, options: .atomic)
        } catch {
            print("Failed to persist tracking queue: \(error.localizedDescription)")
        }
    }

    private func loadSnapshot() {
        guard let data = try? Data(contentsOf: Self.snapshotURL),
              let decoded = try? decoder.decode(TrackingQueueSnapshot.self, from: data) else {
            return
        }
        snapshot = decoded
    }

    private func currentAccessToken() async -> String? {
        await MainActor.run {
            SessionService.shared.accessToken
        }
    }

    private func currentUserID() async -> String? {
        await MainActor.run {
            SessionService.shared.currentUser?.sub
        }
    }

    private static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version) (\(build))"
    }

    private static var apiBaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "AI_BASE_URL") as? String,
              let url = URL(string: raw),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return URL(string: "http://localhost:8000")
        }

        var rebuilt = URLComponents()
        rebuilt.scheme = components.scheme
        rebuilt.host = components.host
        rebuilt.port = components.port
        return rebuilt.url
    }

    private static var snapshotURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = directory.appendingPathComponent("Tracking", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("tracking-queue.json")
    }

    private static func nowMS() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private static func loadDeviceID() -> String {
        let key = "lumen_tracking_device_id"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let value = UUID().uuidString.lowercased()
        UserDefaults.standard.set(value, forKey: key)
        return value
    }
}

enum ReelTrackingIdentity {
    static func make(text: String, category: String, difficulty: String) -> String {
        let source = "\(text.lowercased())|\(category.lowercased())|\(difficulty.lowercased())"
        let digest = SHA256.hash(data: Data(source.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

extension EnglishPhrase {
    var trackingReelID: String {
        ReelTrackingIdentity.make(text: text, category: category, difficulty: difficulty.rawValue)
    }
}

extension FavoritePhrase {
    var trackingReelID: String {
        if !reelID.isEmpty {
            return reelID
        }
        return ReelTrackingIdentity.make(text: text, category: category, difficulty: difficulty)
    }
}

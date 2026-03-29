import Foundation
import SwiftData

struct SavedReelRecord: Codable, Equatable {
    let reelID: String
    let text: String
    let translation: String
    let category: String
    let difficulty: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case reelID = "reel_id"
        case text
        case translation
        case category
        case difficulty
        case createdAt = "created_at"
    }
}

private struct SavedReelsResponse: Codable {
    let items: [SavedReelRecord]
}

private struct SaveReelRequestPayload: Codable {
    let text: String
    let translation: String
    let category: String
    let difficulty: String
}

private struct SaveReelResponse: Codable {
    let item: SavedReelRecord
}

struct SavedReelMigrationItem: Codable {
    let reelID: String
    let text: String
    let translation: String
    let category: String
    let difficulty: String

    enum CodingKeys: String, CodingKey {
        case reelID = "reel_id"
        case text
        case translation
        case category
        case difficulty
    }
}

private struct SavedReelsMigrationRequest: Codable {
    let items: [SavedReelMigrationItem]
}

private struct SavedReelsMigrationResponse: Codable {
    let migratedCount: Int
    let items: [SavedReelRecord]

    enum CodingKeys: String, CodingKey {
        case migratedCount = "migrated_count"
        case items
    }
}

private struct PendingSavedReelOperation: Codable {
    enum Action: String, Codable {
        case save
        case unsave
    }

    let userID: String
    let reelID: String
    let action: Action
    let payload: SavedReelMigrationItem?
    let updatedAt: Date
}

actor SavedReelsService {
    static let shared = SavedReelsService()

    private var apiBaseURL: URL? {
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

    private init() {}

    func fetchSavedReels(accessToken: String) async throws -> [SavedReelRecord] {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid saved reels base URL")
        }

        let endpoint = base.appendingPathComponent("v1").appendingPathComponent("reels").appendingPathComponent("saved")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(extractSavedReelsBackendErrorDetail(from: data) ?? "Failed to load saved reels")
        }

        return try makeLumenISO8601Decoder().decode(SavedReelsResponse.self, from: data).items
    }

    func enqueueSave(userID: String, phrase: EnglishPhrase) async {
        let operation = PendingSavedReelOperation(
            userID: userID,
            reelID: phrase.trackingReelID,
            action: .save,
            payload: SavedReelMigrationItem(
                reelID: phrase.trackingReelID,
                text: phrase.text,
                translation: phrase.translation,
                category: phrase.category,
                difficulty: phrase.difficulty.rawValue
            ),
            updatedAt: .now
        )
        persist(operation: operation)
    }

    func enqueueUnsave(userID: String, reelID: String) async {
        let operation = PendingSavedReelOperation(
            userID: userID,
            reelID: reelID,
            action: .unsave,
            payload: nil,
            updatedAt: .now
        )
        persist(operation: operation)
    }

    func flushPending(accessToken: String, userID: String) async {
        let operations = loadPendingOperations().filter { $0.userID == userID }
        guard !operations.isEmpty else { return }

        for operation in operations {
            do {
                switch operation.action {
                case .save:
                    if let payload = operation.payload {
                        _ = try await saveReel(accessToken: accessToken, reelID: operation.reelID, payload: payload)
                    }
                case .unsave:
                    try await unsaveReel(accessToken: accessToken, reelID: operation.reelID)
                }
                removePendingOperation(for: operation.userID, reelID: operation.reelID)
            } catch {
                Logger.shared.warning("Saved reel sync failed for \(operation.reelID): \(error.localizedDescription)")
            }
        }
    }

    func pendingSaveReelIDs(for userID: String) -> Set<String> {
        Set(
            loadPendingOperations()
                .filter { $0.userID == userID && $0.action == .save }
                .map(\.reelID)
        )
    }

    func migrateLegacyFavorites(accessToken: String, items: [SavedReelMigrationItem]) async throws -> [SavedReelRecord] {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid saved reels base URL")
        }
        guard !items.isEmpty else { return [] }

        let endpoint = base
            .appendingPathComponent("v1")
            .appendingPathComponent("reels")
            .appendingPathComponent("saved")
            .appendingPathComponent("migrate")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(SavedReelsMigrationRequest(items: items))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(extractSavedReelsBackendErrorDetail(from: data) ?? "Failed to migrate saved reels")
        }

        return try makeLumenISO8601Decoder().decode(SavedReelsMigrationResponse.self, from: data).items
    }

    private func saveReel(accessToken: String, reelID: String, payload: SavedReelMigrationItem) async throws -> SavedReelRecord {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid saved reels base URL")
        }

        let endpoint = base
            .appendingPathComponent("v1")
            .appendingPathComponent("reels")
            .appendingPathComponent(reelID)
            .appendingPathComponent("save")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            SaveReelRequestPayload(
                text: payload.text,
                translation: payload.translation,
                category: payload.category,
                difficulty: payload.difficulty
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(extractSavedReelsBackendErrorDetail(from: data) ?? "Failed to save reel")
        }

        return try makeLumenISO8601Decoder().decode(SaveReelResponse.self, from: data).item
    }

    private func unsaveReel(accessToken: String, reelID: String) async throws {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid saved reels base URL")
        }

        let endpoint = base
            .appendingPathComponent("v1")
            .appendingPathComponent("reels")
            .appendingPathComponent(reelID)
            .appendingPathComponent("save")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(extractSavedReelsBackendErrorDetail(from: data) ?? "Failed to unsave reel")
        }
    }

    private func persist(operation: PendingSavedReelOperation) {
        var operations = loadPendingOperations()
        operations.removeAll { $0.userID == operation.userID && $0.reelID == operation.reelID }
        operations.append(operation)
        savePendingOperations(operations)
    }

    private func removePendingOperation(for userID: String, reelID: String) {
        var operations = loadPendingOperations()
        operations.removeAll { $0.userID == userID && $0.reelID == reelID }
        savePendingOperations(operations)
    }

    private func loadPendingOperations() -> [PendingSavedReelOperation] {
        guard
            let data = try? Data(contentsOf: savedReelsPendingQueueURL()),
            let operations = try? JSONDecoder().decode([PendingSavedReelOperation].self, from: data)
        else {
            return []
        }
        return operations.sorted { $0.updatedAt < $1.updatedAt }
    }

    private func savePendingOperations(_ operations: [PendingSavedReelOperation]) {
        if operations.isEmpty {
            try? FileManager.default.removeItem(at: savedReelsPendingQueueURL())
            return
        }
        if let data = try? JSONEncoder().encode(operations) {
            try? data.write(to: savedReelsPendingQueueURL(), options: .atomic)
        }
    }
}

private func makeLumenISO8601Decoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}

private func savedReelsPendingQueueURL() -> URL {
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let folder = directory.appendingPathComponent("SavedReels", isDirectory: true)
    if !FileManager.default.fileExists(atPath: folder.path) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }
    return folder.appendingPathComponent("pending-saved-reels.json")
}

private func extractSavedReelsBackendErrorDetail(from data: Data) -> String? {
    if
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let detail = json["detail"] as? String,
        !detail.isEmpty
    {
        return detail
    }
    return nil
}

enum SavedReelsLocalCache {
    static func hasCompletedLegacyMigration(for userID: String) -> Bool {
        UserDefaults.standard.bool(forKey: "saved_reels_legacy_migrated_\(userID)")
    }

    static func markLegacyMigrationCompleted(for userID: String) {
        UserDefaults.standard.set(true, forKey: "saved_reels_legacy_migrated_\(userID)")
    }

    @MainActor
    static func reconcile(
        modelContext: ModelContext,
        currentUserID: String,
        remoteItems: [SavedReelRecord],
        preservingPendingSaveReelIDs: Set<String> = []
    ) throws {
        let descriptor = FetchDescriptor<FavoritePhrase>()
        let localItems = try modelContext.fetch(descriptor)
        let currentUserItems = localItems.filter { $0.userID == currentUserID }
        let remoteByReelID = Dictionary(uniqueKeysWithValues: remoteItems.map { ($0.reelID, $0) })

        for favorite in currentUserItems
        where remoteByReelID[favorite.reelID] == nil
            && !preservingPendingSaveReelIDs.contains(favorite.reelID)
        {
            modelContext.delete(favorite)
        }

        for remote in remoteItems {
            if let existing = currentUserItems.first(where: { $0.reelID == remote.reelID }) {
                existing.userID = currentUserID
                existing.text = remote.text
                existing.translation = remote.translation
                existing.category = remote.category
                existing.difficulty = remote.difficulty
                existing.dateSaved = remote.createdAt
                existing.isPendingSync = false
                existing.lastSyncedAt = .now
            } else {
                modelContext.insert(
                    FavoritePhrase(
                        reelID: remote.reelID,
                        userID: currentUserID,
                        text: remote.text,
                        translation: remote.translation,
                        category: remote.category,
                        difficulty: remote.difficulty,
                        dateSaved: remote.createdAt,
                        isPendingSync: false,
                        lastSyncedAt: .now
                    )
                )
            }
        }

        try modelContext.save()
    }
}

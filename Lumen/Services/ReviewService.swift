import Foundation

enum ReviewResultValue: String, Codable, CaseIterable, Identifiable {
    case failed
    case hard
    case medium
    case easy

    var id: String { rawValue }
    var title: String {
        switch self {
        case .failed: return NativeLanguageLocalization.localizedString(forKey: "review.result.failed", fallback: "Failed")
        case .hard: return NativeLanguageLocalization.localizedString(forKey: "review.result.hard", fallback: "Hard")
        case .medium: return NativeLanguageLocalization.localizedString(forKey: "review.result.medium", fallback: "Medium")
        case .easy: return NativeLanguageLocalization.localizedString(forKey: "review.result.easy", fallback: "Easy")
        }
    }
}

struct ReviewItem: Codable, Identifiable {
    let id: Int
    let reviewType: String
    let status: String
    let lastResult: String?
    let promptText: String
    let answerText: String?
    let translation: String?
    let explanation: String?
    let example: String?
    let topic: String?
    let difficulty: String?
    let sourceReelID: String?
    let importanceScore: Int
    let dueDate: String
    let overdueDays: Int

    enum CodingKeys: String, CodingKey {
        case id
        case reviewType = "review_type"
        case status
        case lastResult = "last_result"
        case promptText = "prompt_text"
        case answerText = "answer_text"
        case translation
        case explanation
        case example
        case topic
        case difficulty
        case sourceReelID = "source_reel_id"
        case importanceScore = "importance_score"
        case dueDate = "due_date"
        case overdueDays = "overdue_days"
    }
}

struct ReviewTodayGroup: Codable, Identifiable {
    let reviewType: String
    var items: [ReviewItem]

    var id: String { reviewType }

    enum CodingKeys: String, CodingKey {
        case reviewType = "review_type"
        case items
    }
}

struct ReviewTodayResponse: Codable {
    let hasItems: Bool
    let totalDueCount: Int
    var groups: [ReviewTodayGroup]
    let generatedToday: [String: Int]
    let generatedAt: String

    enum CodingKeys: String, CodingKey {
        case hasItems = "has_items"
        case totalDueCount = "total_due_count"
        case groups
        case generatedToday = "generated_today"
        case generatedAt = "generated_at"
    }

    init(
        hasItems: Bool,
        totalDueCount: Int,
        groups: [ReviewTodayGroup],
        generatedToday: [String: Int],
        generatedAt: String
    ) {
        self.hasItems = hasItems
        self.totalDueCount = totalDueCount
        self.groups = groups
        self.generatedToday = generatedToday
        self.generatedAt = generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let groups = try container.decodeIfPresent([ReviewTodayGroup].self, forKey: .groups) ?? []
        let totalDueCount = try container.decodeIfPresent(Int.self, forKey: .totalDueCount) ?? groups.reduce(0) { $0 + $1.items.count }
        let hasItems = try container.decodeIfPresent(Bool.self, forKey: .hasItems) ?? !groups.isEmpty
        let generatedToday = try container.decodeIfPresent([String: Int].self, forKey: .generatedToday) ?? ["total": 0, "queued_generation": 0]
        let generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt) ?? ""

        self.init(
            hasItems: hasItems,
            totalDueCount: totalDueCount,
            groups: groups,
            generatedToday: generatedToday,
            generatedAt: generatedAt
        )
    }
}

struct ReviewResultRequestPayload: Codable {
    let result: String
    let tz: String
    let clientResultID: String?

    enum CodingKeys: String, CodingKey {
        case result
        case tz
        case clientResultID = "client_result_id"
    }
}

struct ReviewResultResponse: Codable {
    let reviewItemID: Int
    let status: String
    let result: String
    let nextReviewDate: String
    let reviewCount: Int
    let easyStreak: Int
    let consecutiveFailures: Int

    enum CodingKeys: String, CodingKey {
        case reviewItemID = "review_item_id"
        case status
        case result
        case nextReviewDate = "next_review_date"
        case reviewCount = "review_count"
        case easyStreak = "easy_streak"
        case consecutiveFailures = "consecutive_failures"
    }
}

final class ReviewService {
    static let shared = ReviewService()

    private init() {}

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

    func fetchToday(accessToken: String, timeZoneIdentifier: String = TimeZone.current.identifier) async throws -> ReviewTodayResponse {
        Task {
            await TrackingService.shared.flushIfNeeded(force: true)
        }

        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid review base URL")
        }

        var components = URLComponents(url: base.appendingPathComponent("v1").appendingPathComponent("review").appendingPathComponent("today"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "tz", value: timeZoneIdentifier)]

        guard let url = components?.url else {
            throw AIServiceError.networkError("Invalid review URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 45

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Failed to load review queue")
        }

        return try JSONDecoder().decode(ReviewTodayResponse.self, from: data)
    }

    func submitResult(
        accessToken: String,
        reviewItemID: Int,
        result: ReviewResultValue,
        clientResultID: String? = nil,
        timeZoneIdentifier: String = TimeZone.current.identifier
    ) async throws -> ReviewResultResponse {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid review base URL")
        }

        let url = base
            .appendingPathComponent("v1")
            .appendingPathComponent("review")
            .appendingPathComponent(String(reviewItemID))
            .appendingPathComponent("result")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 45
        request.httpBody = try JSONEncoder().encode(
            ReviewResultRequestPayload(result: result.rawValue, tz: timeZoneIdentifier, clientResultID: clientResultID)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Failed to submit review result")
        }

        return try JSONDecoder().decode(ReviewResultResponse.self, from: data)
    }

    private static func extractBackendErrorDetail(from data: Data) -> String? {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return raw["detail"] as? String
    }
}

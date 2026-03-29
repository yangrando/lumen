import Foundation

struct TopicPerformanceSummary: Codable, Identifiable {
    let topic: String
    let reelsViewed: Int
    let meaningfulReelsCompleted: Int
    let comprehensionScore: Int?
    let speakingScore: Int?
    let helpRate: Double
    let translationRate: Double

    var id: String { topic }

    enum CodingKeys: String, CodingKey {
        case topic
        case reelsViewed = "reels_viewed"
        case meaningfulReelsCompleted = "meaningful_reels_completed"
        case comprehensionScore = "comprehension_score"
        case speakingScore = "speaking_score"
        case helpRate = "help_rate"
        case translationRate = "translation_rate"
    }
}

struct ProgressOverview: Codable {
    let hasData: Bool
    let currentStreak: Int
    let totalStudyDays: Int
    let weeklyGoalTarget: Int
    let weeklyGoalProgress: Int
    let minutesStudiedThisWeek: Int
    let meaningfulReelsCompleted: Int
    let reviewsCompleted: Int
    let speakingSessionsCompleted: Int
    let comprehensionScore: Int?
    let speakingConfidenceScore: Int?
    let strongestTopics: [TopicPerformanceSummary]
    let weakestTopics: [TopicPerformanceSummary]
    let weekStartDate: String
    let weekEndDate: String
    let generatedAt: String
    let calculationVersion: String

    enum CodingKeys: String, CodingKey {
        case hasData = "has_data"
        case currentStreak = "current_streak"
        case totalStudyDays = "total_study_days"
        case weeklyGoalTarget = "weekly_goal_target"
        case weeklyGoalProgress = "weekly_goal_progress"
        case minutesStudiedThisWeek = "minutes_studied_this_week"
        case meaningfulReelsCompleted = "meaningful_reels_completed"
        case reviewsCompleted = "reviews_completed"
        case speakingSessionsCompleted = "speaking_sessions_completed"
        case comprehensionScore = "comprehension_score"
        case speakingConfidenceScore = "speaking_confidence_score"
        case strongestTopics = "strongest_topics"
        case weakestTopics = "weakest_topics"
        case weekStartDate = "week_start_date"
        case weekEndDate = "week_end_date"
        case generatedAt = "generated_at"
        case calculationVersion = "calculation_version"
    }

    init(
        hasData: Bool,
        currentStreak: Int,
        totalStudyDays: Int,
        weeklyGoalTarget: Int,
        weeklyGoalProgress: Int,
        minutesStudiedThisWeek: Int,
        meaningfulReelsCompleted: Int,
        reviewsCompleted: Int,
        speakingSessionsCompleted: Int,
        comprehensionScore: Int?,
        speakingConfidenceScore: Int?,
        strongestTopics: [TopicPerformanceSummary],
        weakestTopics: [TopicPerformanceSummary],
        weekStartDate: String,
        weekEndDate: String,
        generatedAt: String,
        calculationVersion: String
    ) {
        self.hasData = hasData
        self.currentStreak = currentStreak
        self.totalStudyDays = totalStudyDays
        self.weeklyGoalTarget = weeklyGoalTarget
        self.weeklyGoalProgress = weeklyGoalProgress
        self.minutesStudiedThisWeek = minutesStudiedThisWeek
        self.meaningfulReelsCompleted = meaningfulReelsCompleted
        self.reviewsCompleted = reviewsCompleted
        self.speakingSessionsCompleted = speakingSessionsCompleted
        self.comprehensionScore = comprehensionScore
        self.speakingConfidenceScore = speakingConfidenceScore
        self.strongestTopics = strongestTopics
        self.weakestTopics = weakestTopics
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.generatedAt = generatedAt
        self.calculationVersion = calculationVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let strongestTopics = try container.decodeIfPresent([TopicPerformanceSummary].self, forKey: .strongestTopics) ?? []
        let weakestTopics = try container.decodeIfPresent([TopicPerformanceSummary].self, forKey: .weakestTopics) ?? []
        let totalStudyDays = try container.decodeIfPresent(Int.self, forKey: .totalStudyDays) ?? 0
        let currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        let weeklyGoalTarget = try container.decodeIfPresent(Int.self, forKey: .weeklyGoalTarget) ?? 5
        let weeklyGoalProgress = try container.decodeIfPresent(Int.self, forKey: .weeklyGoalProgress) ?? 0
        let minutesStudiedThisWeek = try container.decodeIfPresent(Int.self, forKey: .minutesStudiedThisWeek) ?? 0
        let meaningfulReelsCompleted = try container.decodeIfPresent(Int.self, forKey: .meaningfulReelsCompleted) ?? 0
        let reviewsCompleted = try container.decodeIfPresent(Int.self, forKey: .reviewsCompleted) ?? 0
        let speakingSessionsCompleted = try container.decodeIfPresent(Int.self, forKey: .speakingSessionsCompleted) ?? 0
        let comprehensionScore = try container.decodeIfPresent(Int.self, forKey: .comprehensionScore)
        let speakingConfidenceScore = try container.decodeIfPresent(Int.self, forKey: .speakingConfidenceScore)
        let weekStartDate = try container.decodeIfPresent(String.self, forKey: .weekStartDate) ?? ""
        let weekEndDate = try container.decodeIfPresent(String.self, forKey: .weekEndDate) ?? ""
        let generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt) ?? ""
        let calculationVersion = try container.decodeIfPresent(String.self, forKey: .calculationVersion) ?? "v1"
        let hasData = try container.decodeIfPresent(Bool.self, forKey: .hasData)
            ?? (totalStudyDays > 0 || meaningfulReelsCompleted > 0 || reviewsCompleted > 0 || speakingSessionsCompleted > 0)

        self.init(
            hasData: hasData,
            currentStreak: currentStreak,
            totalStudyDays: totalStudyDays,
            weeklyGoalTarget: weeklyGoalTarget,
            weeklyGoalProgress: weeklyGoalProgress,
            minutesStudiedThisWeek: minutesStudiedThisWeek,
            meaningfulReelsCompleted: meaningfulReelsCompleted,
            reviewsCompleted: reviewsCompleted,
            speakingSessionsCompleted: speakingSessionsCompleted,
            comprehensionScore: comprehensionScore,
            speakingConfidenceScore: speakingConfidenceScore,
            strongestTopics: strongestTopics,
            weakestTopics: weakestTopics,
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            generatedAt: generatedAt,
            calculationVersion: calculationVersion
        )
    }
}

final class ProgressService {
    static let shared = ProgressService()

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

    func fetchOverview(accessToken: String, timeZoneIdentifier: String = TimeZone.current.identifier) async throws -> ProgressOverview {
        Task {
            await TrackingService.shared.flushIfNeeded(force: true)
        }

        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid progress base URL")
        }

        var components = URLComponents(url: base.appendingPathComponent("v1").appendingPathComponent("progress").appendingPathComponent("overview"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "tz", value: timeZoneIdentifier)
        ]

        guard let url = components?.url else {
            throw AIServiceError.networkError("Invalid progress overview URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Failed to load progress overview")
        }

        return try JSONDecoder().decode(ProgressOverview.self, from: data)
    }

    private static func extractBackendErrorDetail(from data: Data) -> String? {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return raw["detail"] as? String
    }
}

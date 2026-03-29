import Foundation

enum SpeakingPracticeMode: String, Codable {
    case repeatExactly = "repeat_exactly"
}

struct SpeakingAttempt: Codable, Identifiable {
    let id: Int
    let reelID: String?
    let reviewItemID: Int?
    let mode: String
    let targetText: String
    let transcribedText: String
    let score: Int
    let similarityScore: Int
    let missingWords: [String]
    let incorrectWords: [SpeakingIncorrectWord]
    let feedback: String
    let recommendation: String
    let durationSeconds: Double?
    let audioStorageKey: String?
    let transcript: String?
    let reviewOutcome: ReviewResultResponse?
    let transcriptionConfidence: Double?
    let transcriptionSource: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case reelID = "reel_id"
        case reviewItemID = "review_item_id"
        case mode
        case targetText = "target_text"
        case transcribedText = "transcribed_text"
        case score
        case similarityScore = "similarity_score"
        case missingWords = "missing_words"
        case incorrectWords = "incorrect_words"
        case feedback
        case recommendation
        case durationSeconds = "duration_seconds"
        case audioStorageKey = "audio_storage_key"
        case transcript
        case reviewOutcome = "review_outcome"
        case transcriptionConfidence = "transcription_confidence"
        case transcriptionSource = "transcription_source"
        case createdAt = "created_at"
    }
}

struct SpeakingIncorrectWord: Codable, Identifiable {
    let expected: String
    let heard: String

    var id: String { "\(expected)|\(heard)" }
}

struct SpeakingHistoryResponse: Codable {
    let items: [SpeakingAttempt]
    let count: Int
}

final class SpeakingPracticeService {
    static let shared = SpeakingPracticeService()

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

    func analyze(
        accessToken: String,
        audioFileURL: URL,
        mode: SpeakingPracticeMode,
        targetText: String,
        reelID: String?,
        reviewItemID: Int?,
        durationSeconds: Double?,
        clientAttemptID: String,
        transcriptHint: String? = nil,
        timeZoneIdentifier: String = TimeZone.current.identifier
    ) async throws -> SpeakingAttempt {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid speaking base URL")
        }

        let url = base
            .appendingPathComponent("v1")
            .appendingPathComponent("speaking")
            .appendingPathComponent("analyze")

        let audioData = try Data(contentsOf: audioFileURL)
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 240
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(
            boundary: boundary,
            audioData: audioData,
            filename: audioFileURL.lastPathComponent,
            fields: [
                "mode": mode.rawValue,
                "target_text": targetText,
                "reel_id": reelID,
                "review_item_id": reviewItemID.map(String.init),
                "duration_seconds": durationSeconds.map { String(format: "%.2f", $0) },
                "client_attempt_id": clientAttemptID,
                "client_transcript_hint": transcriptHint,
                "tz": timeZoneIdentifier
            ]
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Failed to analyze speaking attempt")
        }

        return try JSONDecoder().decode(SpeakingAttempt.self, from: data)
    }

    func fetchHistory(
        accessToken: String,
        limit: Int = 20
    ) async throws -> SpeakingHistoryResponse {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid speaking base URL")
        }

        var components = URLComponents(
            url: base.appendingPathComponent("v1").appendingPathComponent("speaking").appendingPathComponent("history"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        guard let url = components?.url else {
            throw AIServiceError.networkError("Invalid speaking history URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Failed to load speaking history")
        }

        return try JSONDecoder().decode(SpeakingHistoryResponse.self, from: data)
    }

    private func buildMultipartBody(
        boundary: String,
        audioData: Data,
        filename: String,
        fields: [String: String?]
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        for (key, value) in fields {
            guard let value, !value.isEmpty else { continue }
            body.appendString("--\(boundary)\(lineBreak)")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.appendString(value)
            body.appendString(lineBreak)
        }

        body.appendString("--\(boundary)\(lineBreak)")
        body.appendString("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\(lineBreak)")
        body.appendString("Content-Type: audio/m4a\(lineBreak)\(lineBreak)")
        body.append(audioData)
        body.appendString(lineBreak)
        body.appendString("--\(boundary)--\(lineBreak)")
        return body
    }

    private static func extractBackendErrorDetail(from data: Data) -> String? {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return raw["detail"] as? String
    }
}

private extension Data {
    mutating func appendString(_ value: String) {
        append(Data(value.utf8))
    }
}

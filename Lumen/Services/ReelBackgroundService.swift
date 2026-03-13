import Foundation

actor ReelBackgroundService {
    static let shared = ReelBackgroundService()

    private var cache: [String: URL] = [:]
    private var failedUntil: [String: Date] = [:]

    private var generateEndpoint: URL? {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "AI_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty, let generateURL = URL(string: raw) else {
            return URL(string: "http://localhost:8000/ai/background")
        }

        if raw.hasSuffix("/ai/generate") {
            return URL(string: raw.replacingOccurrences(of: "/ai/generate", with: "/ai/background"))
        }

        if raw.hasSuffix("/ai/background") {
            return generateURL
        }

        return URL(string: "/ai/background", relativeTo: generateURL)
    }

    func urlForPhrase(
        text: String,
        category: String,
        difficulty: String,
        seed: String
    ) async throws -> URL {
        let key = cacheKey(text: text, category: category, difficulty: difficulty, seed: seed)

        if let holdUntil = failedUntil[key], holdUntil > Date() {
            throw AIServiceError.networkError("Background generation temporarily unavailable")
        }

        if let cached = cache[key] {
            return cached
        }

        guard let endpoint = generateEndpoint else {
            throw AIServiceError.networkError("Invalid background endpoint")
        }
        guard let token = await MainActor.run(body: { SessionService.shared.accessToken }) else {
            throw AIServiceError.unauthenticated
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "text": text,
            "category": category,
            "difficulty": difficulty,
            "seed": seed
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AIServiceError.networkError("Invalid response from server (Status: \(statusCode))")
        }

        let payload = try JSONDecoder().decode(ReelBackgroundResponse.self, from: data)

        if payload.fallback == true {
            let retryAfter = TimeInterval(payload.retryAfterSeconds ?? 600)
            failedUntil[key] = Date().addingTimeInterval(max(60, retryAfter))
            throw AIServiceError.networkError("Background provider unavailable")
        }

        guard let imageURL = payload.imageURL,
              !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = URL(string: imageURL) else {
            failedUntil[key] = Date().addingTimeInterval(300)
            throw AIServiceError.decodingError("Invalid background URL")
        }

        cache[key] = url
        failedUntil[key] = nil
        return url
    }

    private func cacheKey(text: String, category: String, difficulty: String, seed: String) -> String {
        [
            text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            difficulty.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            seed.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        ].joined(separator: "|")
    }
}

private struct ReelBackgroundResponse: Decodable {
    let imageURL: String?
    let cached: Bool
    let provider: String?
    let fallback: Bool?
    let retryAfterSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case cached
        case provider
        case fallback
        case retryAfterSeconds = "retry_after_seconds"
    }
}

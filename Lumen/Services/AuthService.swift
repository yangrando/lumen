import Foundation

enum AuthProvider: String {
    case google
    case apple
}

struct AuthRequestPayload: Codable {
    let id_token: String
}

struct EmailSignupRequestPayload: Codable {
    let name: String?
    let email: String
    let password: String
}

struct EmailLoginRequestPayload: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let access_token: String
    let user: AuthUser
}

struct AuthMeResponse: Codable {
    let user: AuthUser
}

struct UserPreferences: Codable {
    let level: String
    let nativeLanguage: String
    let interests: [String]
    let subtopics: [String]
    let objectives: [String]
    let contentStylePreference: String
    let profession: String?

    enum CodingKeys: String, CodingKey {
        case level
        case nativeLanguage = "native_language"
        case interests
        case subtopics
        case objectives
        case contentStylePreference = "content_style_preference"
        case profession
    }

    init(
        level: String,
        nativeLanguage: String,
        interests: [String],
        subtopics: [String] = [],
        objectives: [String],
        contentStylePreference: String = "Mixed",
        profession: String? = nil
    ) {
        self.level = level
        self.nativeLanguage = nativeLanguage
        self.interests = interests
        self.subtopics = subtopics
        self.objectives = objectives
        self.contentStylePreference = contentStylePreference
        self.profession = profession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        level = try container.decode(String.self, forKey: .level)
        nativeLanguage = try container.decode(String.self, forKey: .nativeLanguage)
        interests = try container.decodeIfPresent([String].self, forKey: .interests) ?? []
        subtopics = try container.decodeIfPresent([String].self, forKey: .subtopics) ?? []
        objectives = try container.decodeIfPresent([String].self, forKey: .objectives) ?? []
        contentStylePreference = try container.decodeIfPresent(String.self, forKey: .contentStylePreference) ?? "Mixed"
        profession = try container.decodeIfPresent(String.self, forKey: .profession)
    }
}

struct UserPreferencesResponse: Codable {
    let preferences: UserPreferences
}

struct UserPreferencesRequestPayload: Codable {
    let level: String
    let nativeLanguage: String
    let interests: [String]
    let subtopics: [String]
    let objectives: [String]
    let contentStylePreference: String
    let profession: String?

    enum CodingKeys: String, CodingKey {
        case level
        case nativeLanguage = "native_language"
        case interests
        case subtopics
        case objectives
        case contentStylePreference = "content_style_preference"
        case profession
    }
}

struct AuthUser: Codable {
    let sub: String
    let email: String?
    let provider: String?
    let name: String?
}

final class AuthService {
    static let shared = AuthService()

    private let logger = Logger.shared
    private let cachedPreferencesPrefix = "lumen_cached_preferences_"

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

    var isLocalDevelopment: Bool {
        guard let host = apiBaseURL?.host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1"
    }

    func makeDevelopmentIDToken(for provider: AuthProvider, subject: String = "ios-user") -> String? {
        guard isLocalDevelopment else { return nil }
        return "dev-\(provider.rawValue):\(subject)"
    }

    func login(provider: AuthProvider, idToken: String) async throws -> AuthResponse {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent(provider.rawValue)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AuthRequestPayload(id_token: idToken))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = Self.extractBackendErrorDetail(from: data) ?? "Authentication failed"
            logger.error("Auth failed: \(message)")
            throw LumenError.network(message)
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func signUpWithEmail(name: String?, email: String, password: String) async throws -> AuthResponse {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("signup")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(EmailSignupRequestPayload(name: name, email: email, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LumenError.network(Self.extractBackendErrorDetail(from: data))
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func loginWithEmail(email: String, password: String) async throws -> AuthResponse {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("login")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(EmailLoginRequestPayload(email: email, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LumenError.network(Self.extractBackendErrorDetail(from: data))
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func fetchCurrentUser(accessToken: String) async throws -> AuthUser {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("me")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LumenError.network(Self.extractBackendErrorDetail(from: data))
        }

        return try JSONDecoder().decode(AuthMeResponse.self, from: data).user
    }

    func logout(accessToken: String) async throws {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("logout")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LumenError.network(Self.extractBackendErrorDetail(from: data))
        }
    }

    func deleteAccount(accessToken: String) async throws {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("account")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LumenError.network(Self.extractBackendErrorDetail(from: data))
        }
    }

    func fetchCurrentUserPreferences(accessToken: String) async throws -> UserPreferences {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("users").appendingPathComponent("me").appendingPathComponent("preferences")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LumenError.network(Self.extractBackendErrorDetail(from: data))
        }

        let preferences = try JSONDecoder().decode(UserPreferencesResponse.self, from: data).preferences
        cachePreferences(preferences)
        NativeLanguageLocalization.savePreferredNativeLanguage(preferences.nativeLanguage)
        return preferences
    }

    func updateCurrentUserPreferences(accessToken: String, preferences: UserPreferences) async throws -> UserPreferences {
        guard let base = apiBaseURL else {
            throw LumenError.network()
        }

        let endpoint = base.appendingPathComponent("users").appendingPathComponent("me").appendingPathComponent("preferences")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            UserPreferencesRequestPayload(
                level: preferences.level,
                nativeLanguage: preferences.nativeLanguage,
                interests: preferences.interests,
                subtopics: preferences.subtopics,
                objectives: preferences.objectives,
                contentStylePreference: preferences.contentStylePreference,
                profession: preferences.profession
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LumenError.network(Self.extractBackendErrorDetail(from: data))
        }

        let saved = try JSONDecoder().decode(UserPreferencesResponse.self, from: data).preferences
        cachePreferences(saved)
        NativeLanguageLocalization.savePreferredNativeLanguage(saved.nativeLanguage)
        return saved
    }

    func cachedPreferences(for userID: String?) -> UserPreferences? {
        guard let userID, !userID.isEmpty else { return nil }
        guard let data = UserDefaults.standard.data(forKey: cachedPreferencesPrefix + userID) else {
            return nil
        }
        return try? JSONDecoder().decode(UserPreferences.self, from: data)
    }

    private func cachePreferences(_ preferences: UserPreferences) {
        guard let userID = SessionService.shared.currentUser?.sub, !userID.isEmpty else { return }
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: cachedPreferencesPrefix + userID)
    }

    private static func extractBackendErrorDetail(from data: Data) -> String? {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return raw["detail"] as? String
    }
}

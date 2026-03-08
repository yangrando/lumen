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
    let objectives: [String]

    enum CodingKeys: String, CodingKey {
        case level
        case nativeLanguage = "native_language"
        case interests
        case objectives
    }
}

struct UserPreferencesResponse: Codable {
    let preferences: UserPreferences
}

struct UserPreferencesRequestPayload: Codable {
    let level: String
    let nativeLanguage: String
    let interests: [String]
    let objectives: [String]

    enum CodingKeys: String, CodingKey {
        case level
        case nativeLanguage = "native_language"
        case interests
        case objectives
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
            throw AIServiceError.networkError("Invalid auth base URL")
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
            throw AIServiceError.networkError(message)
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func signUpWithEmail(name: String?, email: String, password: String) async throws -> AuthResponse {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid auth base URL")
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("signup")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(EmailSignupRequestPayload(name: name, email: email, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Sign up failed")
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func loginWithEmail(email: String, password: String) async throws -> AuthResponse {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid auth base URL")
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("login")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(EmailLoginRequestPayload(email: email, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Login failed")
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func fetchCurrentUser(accessToken: String) async throws -> AuthUser {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid auth base URL")
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("me")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Session validation failed")
        }

        return try JSONDecoder().decode(AuthMeResponse.self, from: data).user
    }

    func logout(accessToken: String) async throws {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid auth base URL")
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("logout")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Logout failed")
        }
    }

    func deleteAccount(accessToken: String) async throws {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid auth base URL")
        }

        let endpoint = base.appendingPathComponent("auth").appendingPathComponent("account")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Delete account failed")
        }
    }

    func fetchCurrentUserPreferences(accessToken: String) async throws -> UserPreferences {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid auth base URL")
        }

        let endpoint = base.appendingPathComponent("users").appendingPathComponent("me").appendingPathComponent("preferences")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Failed to load preferences")
        }

        return try JSONDecoder().decode(UserPreferencesResponse.self, from: data).preferences
    }

    func updateCurrentUserPreferences(accessToken: String, preferences: UserPreferences) async throws -> UserPreferences {
        guard let base = apiBaseURL else {
            throw AIServiceError.networkError("Invalid auth base URL")
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
                objectives: preferences.objectives
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIServiceError.networkError(Self.extractBackendErrorDetail(from: data) ?? "Failed to save preferences")
        }

        return try JSONDecoder().decode(UserPreferencesResponse.self, from: data).preferences
    }

    private static func extractBackendErrorDetail(from data: Data) -> String? {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return raw["detail"] as? String
    }
}

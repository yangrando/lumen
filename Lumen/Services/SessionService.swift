import Foundation
import Combine

@MainActor
final class SessionService: ObservableObject {
    static let shared = SessionService()

    @Published private(set) var accessToken: String?
    @Published private(set) var currentUser: AuthUser?

    private let tokenKey = "lumen_access_token"

    private init() {
        accessToken = KeychainService.shared.get(tokenKey)
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }

    func saveSession(accessToken: String, user: AuthUser) {
        self.accessToken = accessToken
        self.currentUser = user
        _ = KeychainService.shared.save(accessToken, for: tokenKey)
    }

    func clearSession() {
        accessToken = nil
        currentUser = nil
        KeychainService.shared.delete(tokenKey)
    }

    func logout() async {
        if let token = accessToken {
            try? await AuthService.shared.logout(accessToken: token)
        }
        clearSession()
    }

    func deleteAccount() async throws {
        guard let token = accessToken else {
            clearSession()
            return
        }
        try await AuthService.shared.deleteAccount(accessToken: token)
        clearSession()
    }
}

import Foundation
import Combine

@MainActor
final class SessionService: ObservableObject {
    static let shared = SessionService()

    @Published private(set) var accessToken: String?
    @Published private(set) var currentUser: AuthUser?
    @Published var justCompletedOnboarding = false

    private let tokenKey = "lumen_access_token"
    private let onboardingCompletedPrefix = "lumen_onboarding_completed_"

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

    func ensureCurrentUserLoaded() async {
        guard currentUser == nil, let token = accessToken else { return }
        currentUser = try? await AuthService.shared.fetchCurrentUser(accessToken: token)
    }

    func clearSession() {
        accessToken = nil
        currentUser = nil
        justCompletedOnboarding = false
        KeychainService.shared.delete(tokenKey)
        Task {
            await TrackingService.shared.handleLogout()
        }
    }

    func hasCompletedOnboarding(for userID: String) -> Bool {
        UserDefaults.standard.bool(forKey: onboardingCompletedPrefix + userID)
    }

    func markOnboardingCompleted(for userID: String) {
        UserDefaults.standard.set(true, forKey: onboardingCompletedPrefix + userID)
    }

    func markJustCompletedOnboarding() {
        justCompletedOnboarding = true
    }

    func logout() async {
        if let token = accessToken {
            try? await AuthService.shared.logout(accessToken: token)
        }
        if currentUser?.provider == AuthProvider.google.rawValue {
            SocialAuthService.shared.signOutGoogleIfNeeded()
        }
        clearSession()
    }

    func deleteAccount() async throws {
        guard let token = accessToken else {
            clearSession()
            return
        }
        try await AuthService.shared.deleteAccount(accessToken: token)
        if currentUser?.provider == AuthProvider.google.rawValue {
            SocialAuthService.shared.signOutGoogleIfNeeded()
        }
        clearSession()
    }
}

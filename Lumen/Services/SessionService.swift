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

    private let hasLaunchedKey = "lumen_has_launched"

    private init() {
        // Keychain persists across uninstalls on iOS; UserDefaults does not.
        // On a fresh install, clear any leftover token so login is always required.
        if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            KeychainService.shared.delete(tokenKey)
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
        }
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
        do {
            currentUser = try await AuthService.shared.fetchCurrentUser(accessToken: token)
        } catch {
            Logger.shared.warning("ensureCurrentUserLoaded failed — user-specific features may be unavailable: \(error.localizedDescription)")
        }
    }

    func clearSession() {
        accessToken = nil
        currentUser = nil
        justCompletedOnboarding = false
        KeychainService.shared.delete(tokenKey)
        NativeLanguageLocalization.clearPreferredNativeLanguage()
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
        let token = accessToken
        let provider = currentUser?.provider
        clearSession()  // Keychain is cleared immediately — never depends on network success
        if let token {
            try? await AuthService.shared.logout(accessToken: token)
        }
        if provider == AuthProvider.google.rawValue {
            SocialAuthService.shared.signOutGoogleIfNeeded()
        }
    }

    func deleteAccount() async throws {
        guard let token = accessToken else {
            clearSession()
            return
        }
        let provider = currentUser?.provider
        clearSession()  // Keychain cleared before the network call
        try await AuthService.shared.deleteAccount(accessToken: token)
        if provider == AuthProvider.google.rawValue {
            SocialAuthService.shared.signOutGoogleIfNeeded()
        }
    }
}

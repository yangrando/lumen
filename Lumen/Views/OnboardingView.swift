import SwiftUI

struct OnboardingView: View {
    enum OnboardingStep {
        case welcome
        case manualSignUp
        case nativeLanguage
        case levelSelection
        case interests
        case objectives
        case completion
        case feed
    }
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedLevel: EnglishLevel? = nil
    @State private var selectedNativeLanguage: String = "Portuguese (Brazil)"
    @State private var selectedInterests: [UserInterest] = []
    @State private var selectedObjectives: [LearningObjective] = []
    @State private var isAuthenticating = false
    @State private var authErrorMessage: String? = nil
    @State private var authAlertMessage: String? = nil
    @State private var manualAuthMode: WelcomeView.AuthMode = .signUp

    @StateObject private var sessionService = SessionService.shared

    
    var body: some View {
        NavigationStack {
            switch currentStep {
            case .welcome:
                WelcomeView(
                    isLoading: isAuthenticating,
                    errorMessage: authErrorMessage,
                    onContinueWithApple: {
                        Task {
                            await authenticate(with: .apple)
                        }
                    },
                    onContinueWithGoogle: {
                        Task {
                            await authenticate(with: .google)
                        }
                    },
                    onContinueWithEmail: { mode in
                        manualAuthMode = mode
                        authErrorMessage = nil
                        currentStep = .manualSignUp
                    }
                )
            case .manualSignUp:
                ManualSignUpView(
                    mode: manualAuthMode,
                    onBack: {
                        currentStep = .welcome
                    },
                    onAuthenticate: { name, email, password, mode in
                        try await authenticateWithEmail(name: name, email: email, password: password, mode: mode)
                    }
                )
            case .levelSelection:
                LevelSelectionView(onContinue: { level in
                    selectedLevel = level
                    currentStep = .interests
                })
            case .nativeLanguage:
                NativeLanguageSelectionView(
                    selectedLanguage: selectedNativeLanguage,
                    onContinue: { language in
                        selectedNativeLanguage = language
                        currentStep = .levelSelection
                    }
                )
            case .interests:
                InterestsView(onContinue: { interests in
                    selectedInterests = interests
                    currentStep = .objectives
                })
            case .objectives:
                ObjectivesView(onContinue: { objectives in
                    selectedObjectives = objectives
                    currentStep = .completion
                    Task {
                        await persistOnboardingPreferences()
                    }
                })
            case .completion:
                OnboardingCompletionView(onStart: {
                    if let userID = sessionService.currentUser?.sub {
                        sessionService.markOnboardingCompleted(for: userID)
                    }
                    currentStep = .feed
                })
            case .feed:
                ContentView()
            }
        }
        .onAppear {
            Task {
                await restoreSessionIfPossible()
            }
        }
        .alert(LocalizedStrings.commonOk, isPresented: Binding(
            get: { authAlertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    authAlertMessage = nil
                }
            }
        )) {
            Button(LocalizedStrings.commonOk, role: .cancel) {
                authAlertMessage = nil
            }
        } message: {
            Text(authAlertMessage ?? "")
        }
    }

    private func restoreSessionIfPossible() async {
        guard currentStep == .welcome else { return }
        guard let token = sessionService.accessToken else { return }

        do {
            let user = try await AuthService.shared.fetchCurrentUser(accessToken: token)
            sessionService.saveSession(accessToken: token, user: user)
            if await shouldSkipOnboarding(for: user, accessToken: token) {
                currentStep = .feed
            } else {
                currentStep = .nativeLanguage
            }
        } catch {
            sessionService.clearSession()
        }
    }

    private func authenticate(with provider: AuthProvider) async {
        isAuthenticating = true
        authErrorMessage = nil
        authAlertMessage = nil

        do {
            let idToken = try await SocialAuthService.shared.fetchIDToken(for: provider)
            let authResponse = try await AuthService.shared.login(provider: provider, idToken: idToken)
            sessionService.saveSession(accessToken: authResponse.access_token, user: authResponse.user)
            if await shouldSkipOnboarding(for: authResponse.user, accessToken: authResponse.access_token) {
                currentStep = .feed
            } else {
                currentStep = .nativeLanguage
            }
        } catch SocialAuthError.userCancelled {
            sessionService.clearSession()
            currentStep = .welcome
            authAlertMessage = LocalizedStrings.authCancelled
        } catch {
            sessionService.clearSession()
            currentStep = .welcome
            let message = localizedAuthErrorMessage(for: error)
            authErrorMessage = message
            authAlertMessage = message
        }

        isAuthenticating = false
    }

    private func localizedAuthErrorMessage(for error: Error) -> String {
        if let socialError = error as? SocialAuthError {
            switch socialError {
            case .appleTokenUnavailable:
                return LocalizedStrings.authAppleTokenUnavailable
            case .googleNotConfigured:
                return LocalizedStrings.authGoogleNotConfigured
            case .googleSessionFailed, .googleMissingIDToken, .invalidGoogleCallback:
                return LocalizedStrings.authGoogleFailed
            case .userCancelled:
                return LocalizedStrings.authCancelled
            }
        }

        return LocalizedStrings.authLoginFailed
    }

    private func authenticateWithEmail(name: String?, email: String, password: String, mode: WelcomeView.AuthMode) async throws {
        isAuthenticating = true
        defer { isAuthenticating = false }

        let authResponse: AuthResponse
        switch mode {
        case .signIn:
            authResponse = try await AuthService.shared.loginWithEmail(email: email, password: password)
        case .signUp:
            authResponse = try await AuthService.shared.signUpWithEmail(name: name, email: email, password: password)
        }

        sessionService.saveSession(accessToken: authResponse.access_token, user: authResponse.user)
        if await shouldSkipOnboarding(for: authResponse.user, accessToken: authResponse.access_token) {
            currentStep = .feed
        } else {
            currentStep = .nativeLanguage
        }
    }

    private func persistOnboardingPreferences() async {
        guard let token = sessionService.accessToken else { return }
        guard let selectedLevel else { return }

        let preferences = UserPreferences(
            level: selectedLevel.rawValue,
            nativeLanguage: selectedNativeLanguage,
            interests: selectedInterests.map(\.rawValue),
            objectives: selectedObjectives.map(\.rawValue)
        )

        do {
            _ = try await AuthService.shared.updateCurrentUserPreferences(accessToken: token, preferences: preferences)
            if let userID = sessionService.currentUser?.sub {
                sessionService.markOnboardingCompleted(for: userID)
            }
        } catch {
            // Keep onboarding flow uninterrupted; user can edit preferences later.
        }
    }

    private func shouldSkipOnboarding(for user: AuthUser, accessToken: String) async -> Bool {
        if sessionService.hasCompletedOnboarding(for: user.sub) {
            return true
        }

        do {
            let preferences = try await AuthService.shared.fetchCurrentUserPreferences(accessToken: accessToken)
            let hasPreferences = !preferences.interests.isEmpty || !preferences.objectives.isEmpty
            if hasPreferences {
                sessionService.markOnboardingCompleted(for: user.sub)
            }
            return hasPreferences
        } catch {
            return false
        }
    }
}

#Preview {
    OnboardingView()
}

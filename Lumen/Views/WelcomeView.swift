import SwiftUI

enum WelcomeViewMode {
    case signIn
    case signUp
}

struct WelcomeView: View {
    let isLoading: Bool
    let errorMessage: String?
    let onCreateAccount: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer(minLength: 36)

                VStack(spacing: 16) {
                    LumenMark(size: 88, color: LumenColors.accent, glowEnabled: true)

                    LumenWordmark(size: 34, color: LumenColors.ink50, accent: LumenColors.accent)
                }

                Spacer(minLength: 52)

                VStack(spacing: 18) {
                    (
                        Text(LocalizedStrings.welcomeTitlePart1).foregroundStyle(.white)
                        + Text(LocalizedStrings.welcomeTitlePart2).foregroundStyle(LinearGradient.primaryGradient)
                    )
                    .font(LumenFont.grotesk(28, weight: .bold))
                    .multilineTextAlignment(.center)

                    Text(LocalizedStrings.welcomeDescription)
                        .font(LumenFont.grotesk(16, weight: .medium))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 18) {
                    Button(action: onCreateAccount) {
                        Text(LocalizedStrings.welcomeModeSignUp)
                            .font(LumenFont.grotesk(18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .foregroundStyle(.white)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(Capsule())
                            .shadow(color: LumenColors.gradientEnd.opacity(0.26), radius: 22, x: 0, y: 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    HStack(spacing: 5) {
                        Text(LocalizedStrings.welcomeSignInPrompt)
                            .foregroundStyle(LumenColors.textSecondary)
                        Button(LocalizedStrings.welcomeSignInLink) {
                            onSignIn()
                        }
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .fontWeight(.bold)
                    }
                    .font(LumenFont.grotesk(16, weight: .semibold))

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(LumenFont.grotesk(13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }

                    termsText
                        .padding(.top, 18)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }

    private var background: some View {
        ZStack {
            LumenColors.ink900
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    LumenColors.gradientEnd.opacity(0.16),
                    .clear
                ],
                center: .top,
                startRadius: 30,
                endRadius: 360
            )
            .ignoresSafeArea()
        }
    }

    private var termsText: some View {
        VStack(spacing: 6) {
            Text(LocalizedStrings.welcomeTerms)
                .foregroundStyle(LumenColors.textTertiary)

            HStack(spacing: 4) {
                Text(LocalizedStrings.welcomeTermsLink1)
                Text(LocalizedStrings.commonAnd)
                Text(LocalizedStrings.welcomeTermsLink2)
            }
            .foregroundStyle(LumenColors.gradientStart)
        }
        .font(LumenFont.grotesk(12, weight: .medium))
        .multilineTextAlignment(.center)
    }
}

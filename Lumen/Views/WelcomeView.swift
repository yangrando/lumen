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

                VStack(spacing: 18) {
                    Image("LumenLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .shadow(color: LumenColors.gradientEnd.opacity(0.22), radius: 28, x: 0, y: 14)

                    Text(LocalizedStrings.appName)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 52)

                VStack(spacing: 18) {
                    (
                        Text(LocalizedStrings.welcomeTitlePart1).foregroundStyle(.white)
                        + Text(LocalizedStrings.welcomeTitlePart2).foregroundStyle(LinearGradient.primaryGradient)
                    )
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                    Text(LocalizedStrings.welcomeDescription)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 18) {
                    Button(action: onCreateAccount) {
                        Text(LocalizedStrings.welcomeModeSignUp)
                            .font(.system(size: 18, weight: .bold))
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
                        Text("Já tem conta?")
                            .foregroundStyle(LumenColors.textSecondary)
                        Button("clique aqui") {
                            onSignIn()
                        }
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .fontWeight(.bold)
                    }
                    .font(.system(size: 16, weight: .semibold))

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
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
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.07, blue: 0.14),
                    Color(red: 0.05, green: 0.09, blue: 0.16),
                    Color(red: 0.04, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                Text("e")
                Text(LocalizedStrings.welcomeTermsLink2)
            }
            .foregroundStyle(LumenColors.gradientStart)
        }
        .font(.system(size: 12, weight: .medium))
        .multilineTextAlignment(.center)
    }
}

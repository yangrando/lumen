import SwiftUI

struct WelcomeView: View {
    enum AuthMode {
        case signIn
        case signUp
    }

    let isLoading: Bool
    let errorMessage: String?
    let onContinueWithApple: () -> Void
    let onContinueWithGoogle: () -> Void
    let onContinueWithEmail: (AuthMode) -> Void
    @State private var authMode: AuthMode = .signUp

    private var appleButtonTitle: String {
        authMode == .signIn ? LocalizedStrings.welcomeButtonAppleSignIn : LocalizedStrings.welcomeButtonAppleSignUp
    }

    private var googleButtonTitle: String {
        authMode == .signIn ? LocalizedStrings.welcomeButtonGoogleSignIn : LocalizedStrings.welcomeButtonGoogleSignUp
    }

    private var emailButtonTitle: String {
        authMode == .signIn ? LocalizedStrings.welcomeButtonEmailSignIn : LocalizedStrings.welcomeButtonEmailSignUp
    }
    
    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            VStack(spacing: 22) {
                VStack(spacing: 12) {
                    Image("LumenLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)

                    Text(LocalizedStrings.appName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    (
                        Text(LocalizedStrings.welcomeTitlePart1).foregroundStyle(.white)
                        +
                        Text(LocalizedStrings.welcomeTitlePart2).foregroundStyle(LinearGradient.primaryGradient)
                    )
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                    Text(LocalizedStrings.welcomeDescription)
                        .font(.system(size: 16))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 10) {
                    modeButton(title: LocalizedStrings.welcomeModeSignIn, mode: .signIn)
                    modeButton(title: LocalizedStrings.welcomeModeSignUp, mode: .signUp)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    GlassButton(
                        title: appleButtonTitle,
                        icon: "apple.logo",
                        action: onContinueWithApple
                    )
                    .disabled(isLoading)

                    GlassButton(
                        title: googleButtonTitle,
                        icon: "globe",
                        action: onContinueWithGoogle
                    )
                    .disabled(isLoading)

                    GradientButton(
                        title: emailButtonTitle,
                        icon: "envelope.fill",
                        action: {
                            onContinueWithEmail(authMode)
                        }
                    )
                    .disabled(isLoading)

                    Text(LocalizedStrings.welcomeAuthHint)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LumenColors.textSecondary)
                        .padding(.top, 4)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 4)
                    }

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func modeButton(title: String, mode: AuthMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                authMode = mode
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .foregroundStyle(authMode == mode ? .white : LumenColors.textSecondary)
                .background(
                    authMode == mode
                    ? AnyShapeStyle(LinearGradient.primaryGradient)
                    : AnyShapeStyle(Color.white.opacity(0.06))
                )
                .clipShape(Capsule())
        }
    }
}

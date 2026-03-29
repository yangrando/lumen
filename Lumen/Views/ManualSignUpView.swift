import SwiftUI

struct ManualSignUpView: View {
    let mode: WelcomeViewMode
    let isLoading: Bool
    let onBack: () -> Void
    let onToggleMode: (WelcomeViewMode) -> Void
    let onContinueWithApple: (WelcomeViewMode) -> Void
    let onContinueWithGoogle: (WelcomeViewMode) -> Void
    let onAuthenticate: (_ name: String?, _ email: String, _ password: String, _ mode: WelcomeViewMode) async throws -> Void

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.07, blue: 0.14),
                    LumenColors.navyDark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(mode == .signIn ? LocalizedStrings.signinTitle : LocalizedStrings.signupTitle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)

                        Text(mode == .signIn ? LocalizedStrings.signinSubtitle : LocalizedStrings.signupSubtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(LumenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 14) {
                        if mode == .signUp {
                            inputField(title: LocalizedStrings.signupName, text: $fullName)
                        }

                        inputField(title: LocalizedStrings.signupEmail, text: $email, keyboard: .emailAddress)
                        secureField(title: LocalizedStrings.signupPassword, text: $password, isVisible: $showPassword)

                        if mode == .signUp {
                            secureField(title: LocalizedStrings.signupConfirmPassword, text: $confirmPassword, isVisible: $showConfirmPassword)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.62))
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(mode == .signIn ? LocalizedStrings.signinButton : LocalizedStrings.signupCreateButton)
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .foregroundStyle(.white)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting || isLoading)

                    VStack(spacing: 18) {
                        socialDivider

                        HStack(spacing: 14) {
                            compactSocialButton(
                                title: "Google",
                                icon: "globe",
                                action: { onContinueWithGoogle(mode) }
                            )

                            compactSocialButton(
                                title: "Apple",
                                icon: "apple.logo",
                                action: { onContinueWithApple(mode) }
                            )
                        }
                    }

                    HStack(spacing: 5) {
                        Text(mode == .signIn ? "Ainda não tem conta?" : "Já tem conta?")
                            .foregroundStyle(LumenColors.textSecondary)
                        Button(mode == .signIn ? "Criar conta" : "Entrar") {
                            onToggleMode(mode == .signIn ? .signUp : .signIn)
                        }
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .fontWeight(.bold)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var socialDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            Text("OR CONTINUE WITH")
                .font(.system(size: 10, weight: .bold))
                .tracking(2.1)
                .foregroundStyle(Color.white.opacity(0.28))
                .fixedSize()

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private func compactSocialButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white.opacity(0.04))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isSubmitting)
        .opacity((isLoading || isSubmitting) ? 0.6 : 1.0)
    }

    private func inputField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))

            TextField("", text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func secureField(title: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))

            HStack(spacing: 12) {
                Group {
                    if isVisible.wrappedValue {
                        TextField("", text: text)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(.white)

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(LumenColors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func submit() async {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if mode == .signUp && trimmedName.isEmpty {
            errorMessage = LocalizedStrings.signupErrorRequiredFields
            return
        }

        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = LocalizedStrings.signupErrorRequiredFields
            return
        }

        guard trimmedEmail.contains("@") else {
            errorMessage = LocalizedStrings.signupErrorInvalidEmail
            return
        }

        guard password.count >= 6 else {
            errorMessage = LocalizedStrings.signupErrorPasswordLength
            return
        }

        if mode == .signUp {
            guard !confirmPassword.isEmpty, password == confirmPassword else {
                errorMessage = LocalizedStrings.signupErrorPasswordMismatch
                return
            }
        }

        isSubmitting = true
        errorMessage = nil

        do {
            try await onAuthenticate(mode == .signUp ? trimmedName : nil, trimmedEmail, password, mode)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

import SwiftUI

struct ManualSignUpView: View {
    let mode: WelcomeView.AuthMode
    let onBack: () -> Void
    let onAuthenticate: (_ name: String?, _ email: String, _ password: String, _ mode: WelcomeView.AuthMode) async throws -> Void

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
            LumenColors.navyDark
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text(LocalizedStrings.signupBack)
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                    }
                    .padding(.top, 12)

                    Text(mode == .signIn ? LocalizedStrings.signinTitle : LocalizedStrings.signupTitle)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text(mode == .signIn ? LocalizedStrings.signinSubtitle : LocalizedStrings.signupSubtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(LumenColors.textSecondary)

                    if mode == .signUp {
                        inputField(title: LocalizedStrings.signupName, text: $fullName)
                    }
                    inputField(title: LocalizedStrings.signupEmail, text: $email, keyboard: .emailAddress)
                    secureField(
                        title: LocalizedStrings.signupPassword,
                        text: $password,
                        isVisible: $showPassword
                    )
                    if mode == .signUp {
                        secureField(
                            title: LocalizedStrings.signupConfirmPassword,
                            text: $confirmPassword,
                            isVisible: $showConfirmPassword
                        )
                    }

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.red.opacity(0.95))
                    }

                    GradientButton(
                        title: mode == .signIn ? LocalizedStrings.signinButton : LocalizedStrings.signupCreateButton,
                        icon: mode == .signIn ? "person.fill.checkmark" : "person.crop.circle.badge.plus",
                        action: {
                            Task {
                                await submit()
                            }
                        }
                    )
                    .disabled(isSubmitting)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            if isSubmitting {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.35)

                    Text(mode == .signIn ? LocalizedStrings.signinLoading : LocalizedStrings.signupLoading)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: 220)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            }
        }
        .allowsHitTesting(!isSubmitting)
    }

    private func inputField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            TextField("", text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboard)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .foregroundStyle(.white)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func secureField(title: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            HStack {
                Group {
                    if isVisible.wrappedValue {
                        TextField("", text: text)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(LumenColors.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .foregroundStyle(.white)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
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

#Preview {
    ManualSignUpView(mode: .signUp, onBack: { }, onAuthenticate: { _, _, _, _ in })
}

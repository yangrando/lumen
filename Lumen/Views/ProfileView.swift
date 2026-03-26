import SwiftUI

struct ProfileView: View {
    let accessToken: String
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionService = SessionService.shared

    @State private var currentUser: AuthUser?
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var accountActionError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LumenColors.navyDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            profileHero
                            settingsSection
                            accountActions
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                        .padding(.bottom, 44)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert(LocalizedStrings.accountLogoutConfirmTitle, isPresented: $showLogoutConfirm) {
                Button(LocalizedStrings.accountCancel, role: .cancel) {}
                Button(LocalizedStrings.accountLogout, role: .destructive) {
                    Task {
                        await sessionService.logout()
                        dismiss()
                    }
                }
            } message: {
                Text(LocalizedStrings.accountLogoutConfirmMessage)
            }
            .alert(LocalizedStrings.accountDeleteConfirmTitle, isPresented: $showDeleteConfirm) {
                Button(LocalizedStrings.accountCancel, role: .cancel) {}
                Button(LocalizedStrings.accountDelete, role: .destructive) {
                    Task {
                        do {
                            try await sessionService.deleteAccount()
                            dismiss()
                        } catch {
                            accountActionError = error.localizedDescription
                        }
                    }
                }
            } message: {
                Text(LocalizedStrings.accountDeleteConfirmMessage)
            }
            .alert(LocalizedStrings.feedErrorTitle, isPresented: Binding(
                get: { accountActionError != nil },
                set: { isPresented in if !isPresented { accountActionError = nil } }
            )) {
                Button(LocalizedStrings.commonOk, role: .cancel) {}
            } message: {
                Text(accountActionError ?? "")
            }
            .task {
                if currentUser == nil {
                    currentUser = sessionService.currentUser
                }
                guard currentUser == nil else { return }
                currentUser = try? await AuthService.shared.fetchCurrentUser(accessToken: accessToken)
            }
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Button {
                    onClose()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }

                Spacer()
            }
            .padding(.horizontal, 24)

            Text("Profile")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            HStack {
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .opacity(0)
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(
            Rectangle()
                .fill(LumenColors.navyDark.opacity(0.98))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
        )
    }

    private var profileHero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LumenColors.gradientStart.opacity(0.40),
                                LumenColors.gradientEnd.opacity(0.20),
                                .clear
                            ],
                            center: .center,
                            startRadius: 24,
                            endRadius: 120
                        )
                    )
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(LumenColors.navyLight)
                    .frame(width: 186, height: 186)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.35), lineWidth: 10)
                    }
                    .overlay {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 142, height: 142)
                            .foregroundStyle(.white.opacity(0.92), LumenColors.textSecondary.opacity(0.65))
                    }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(LumenColors.navyLight)
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "pencil")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(LumenColors.gradientStart)
                            }
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            }
                            .offset(x: -12, y: -18)
                    }
                }
                .frame(width: 220, height: 220)
            }

            VStack(spacing: 6) {
                Text(displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(displayHandle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LumenColors.textSecondary)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                NavigationLink {
                    UserPreferencesView(accessToken: accessToken)
                } label: {
                    settingsRow(
                        icon: "person.fill",
                        title: "Profile Settings",
                        tint: Color(red: 0.22, green: 0.28, blue: 0.43),
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    settingsRow(
                        icon: "bell.fill",
                        title: "Notifications",
                        tint: Color(red: 0.22, green: 0.28, blue: 0.43),
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    settingsRow(
                        icon: "questionmark.circle.fill",
                        title: "Help & Feedback",
                        tint: Color(red: 0.22, green: 0.28, blue: 0.43),
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var accountActions: some View {
        VStack(spacing: 18) {
            Button(LocalizedStrings.accountLogout) {
                showLogoutConfirm = true
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.45))

            Button {
                showDeleteConfirm = true
            } label: {
                Text(LocalizedStrings.accountDelete)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.29, blue: 0.29))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(red: 0.79, green: 0.24, blue: 0.27), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow(icon: String, title: String, tint: Color, showsChevron: Bool) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.9))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.47, green: 0.56, blue: 0.67))
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 96)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        }
    }

    private var displayName: String {
        let trimmed = currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Lumen Learner" : trimmed
    }

    private var displayHandle: String {
        let email = currentUser?.email?.lowercased() ?? "lumen_learner"
        let handleBase = email
            .components(separatedBy: "@")
            .first?
            .replacingOccurrences(of: " ", with: "_") ?? "lumen_learner"
        return "@\(handleBase)"
    }
}

#Preview {
    ProfileView(accessToken: "token", onClose: {})
}

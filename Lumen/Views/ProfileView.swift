import SwiftUI

struct ProfileView: View {
    let accessToken: String
    let onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionService = SessionService.shared

    @State private var currentUser: AuthUser?
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var feedbackMessage: AppFeedbackMessage?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background — ink900 + accent radial top-right
                LumenColors.ink900
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [LumenColors.accent.opacity(0.13), .clear],
                    center: .init(x: 1.1, y: -0.05),
                    startRadius: 0,
                    endRadius: 340
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    profileHeader

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            avatarRow
                            statsStrip
                            navigationSection
                            accountActions
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                        .padding(.bottom, 52)
                    }
                }
            }
            .appFeedbackBanner($feedbackMessage)
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
                            await AppFeedbackPresenter.show(
                                UserFacingMessageMapper.successFeedback(message: LocalizedStrings.accountDeleteToastSuccessMessage),
                                in: $feedbackMessage
                            )
                            try? await Task.sleep(nanoseconds: 900_000_000)
                            dismiss()
                        } catch {
                            await AppFeedbackPresenter.show(
                                AppFeedbackMessage(
                                    title: LocalizedStrings.accountDeleteToastErrorTitle,
                                    message: LocalizedStrings.accountDeleteToastErrorMessage,
                                    tone: .error
                                ),
                                in: $feedbackMessage
                            )
                        }
                    }
                }
            } message: {
                Text(LocalizedStrings.accountDeleteConfirmMessage)
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

    // MARK: – Header

    private var profileHeader: some View {
        ZStack {
            HStack {
                Button {
                    onClose()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)
                        .frame(width: 36, height: 36)
                }
                Spacer()
            }
            .padding(.horizontal, 22)

            Text(LocalizedStrings.profileTitle)
                .font(LumenFont.grotesk(22, weight: .semibold))
                .foregroundStyle(LumenColors.ink50)
        }
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(
            Rectangle()
                .fill(LumenColors.ink900.opacity(0.98))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(LumenColors.ink700)
                        .frame(height: 1)
                }
        )
    }

    // MARK: – Avatar row

    private var avatarRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [LumenColors.accent, LumenColors.gradientEnd.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Text(initials)
                    .font(LumenFont.grotesk(24, weight: .medium))
                    .foregroundStyle(LumenColors.ink900)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(LumenFont.grotesk(19, weight: .semibold))
                    .foregroundStyle(LumenColors.ink50)
                    .lineLimit(1)

                Text(userMetaLine)
                    .font(LumenFont.mono(10, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(LumenColors.ink400)
            }

            Spacer()
        }
    }

    // MARK: – Stats strip

    private var statsStrip: some View {
        HStack(spacing: 0) {
            statCell(key: "STREAK", value: "--", unit: "days")

            Rectangle()
                .fill(LumenColors.ink700)
                .frame(width: 1)

            statCell(key: "PHRASES", value: "--", unit: "spoken")

            Rectangle()
                .fill(LumenColors.ink700)
                .frame(width: 1)

            statCell(key: "SCORE", value: "--", unit: "avg %")
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }

    private func statCell(key: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(LumenFont.mono(9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(LumenColors.ink400)

            Text(value)
                .font(LumenFont.grotesk(24, weight: .medium))
                .foregroundStyle(LumenColors.ink50)

            Text(unit)
                .font(LumenFont.grotesk(11))
                .foregroundStyle(LumenColors.ink300)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    // MARK: – Navigation list

    private var navigationSection: some View {
        VStack(spacing: 8) {
            NavigationLink {
                SavedPhrasesView()
            } label: {
                navRow(label: LocalizedStrings.feedSavedPhrases, rightText: "")
            }
            .buttonStyle(.plain)

            NavigationLink {
                ReviewTodayView(accessToken: accessToken)
            } label: {
                navRow(label: LocalizedStrings.profileReviewToday, rightText: "")
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProgressOverviewView(accessToken: accessToken)
            } label: {
                navRow(label: LocalizedStrings.profileProgressOverview, rightText: "")
            }
            .buttonStyle(.plain)

            NavigationLink {
                UserPreferencesView(accessToken: accessToken)
            } label: {
                navRow(label: LocalizedStrings.profileProfileSettings, rightText: "")
            }
            .buttonStyle(.plain)

            Button(action: {}) {
                navRow(label: LocalizedStrings.profileNotifications, rightText: "08:30 · 19:00")
            }
            .buttonStyle(.plain)

            Button(action: {}) {
                navRow(label: LocalizedStrings.profileHelpFeedback, rightText: "")
            }
            .buttonStyle(.plain)
        }
    }

    private func navRow(label: String, rightText: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(LumenFont.grotesk(14, weight: .medium))
                .foregroundStyle(LumenColors.ink50)

            Spacer()

            if !rightText.isEmpty {
                Text(rightText)
                    .font(LumenFont.grotesk(13))
                    .foregroundStyle(LumenColors.ink400)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LumenColors.ink500)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(LumenColors.ink800)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }

    // MARK: – Account actions

    private var accountActions: some View {
        VStack(spacing: 10) {
            LumenButton(kind: .text, label: LocalizedStrings.accountLogout) {
                showLogoutConfirm = true
            }

            LumenButton(kind: .danger, size: .lg, isFullWidth: true, label: LocalizedStrings.accountDelete) {
                showDeleteConfirm = true
            }
        }
        .padding(.top, 6)
    }

    // MARK: – Helpers

    private var initials: String {
        let name = displayName
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }

    private var displayName: String {
        let trimmed = currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? LocalizedStrings.profileDefaultName : trimmed
    }

    private var userMetaLine: String {
        let email = currentUser?.email?.lowercased() ?? ""
        let handle = email.components(separatedBy: "@").first ?? "lumen"
        return handle.uppercased()
    }
}

#Preview {
    ProfileView(accessToken: "token", onClose: {})
}

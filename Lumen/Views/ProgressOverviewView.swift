import SwiftUI

struct ProgressOverviewView: View {
    let accessToken: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProgressOverviewViewModel()
    @StateObject private var xpTracker = XPTracker.shared

    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    loadingState
                } else if let errorMessage = viewModel.errorMessage {
                    errorState(message: errorMessage)
                } else if let overview = viewModel.overview {
                    if overview.hasData {
                        content(overview: overview)
                    } else {
                        emptyState
                    }
                } else {
                    emptyState
                }
            }
        }
        .navigationTitle(LocalizedStrings.progressTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            LumenNavigationBackButton {
                dismiss()
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .task {
            xpTracker.load(for: SessionService.shared.currentUser?.sub)
            if viewModel.overview == nil && !viewModel.isLoading {
                await viewModel.load(accessToken: accessToken)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)

            Text(LocalizedStrings.progressLoadingTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.progressLoadingDescription)
                .font(.system(size: 14))
                .foregroundStyle(LumenColors.textSecondary)
        }
        .padding(.horizontal, 24)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.88))

            Text(LocalizedStrings.progressErrorTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.load(accessToken: accessToken)
                }
            } label: {
                Text(LocalizedStrings.commonRetry)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.88))

            Text(LocalizedStrings.progressEmptyTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.progressEmptyDescription)
                .font(.system(size: 14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    private func content(overview: ProgressOverview) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                highlightCard(overview: overview)

                HStack(spacing: 14) {
                    statCard(title: "Study Days", value: "\(overview.totalStudyDays)", caption: "all time")
                    statCard(title: "This Week", value: "\(overview.minutesStudiedThisWeek)m", caption: "\(overview.meaningfulReelsCompleted) meaningful reels")
                }

                HStack(spacing: 14) {
                    statCard(title: "Reviews", value: "\(overview.reviewsCompleted)", caption: "completed this week")
                    statCard(title: "Speaking", value: "\(overview.speakingSessionsCompleted)", caption: "completed this week")
                }

                statCard(title: "XP", value: "\(xpTracker.totalXP)", caption: "earned from learning actions")

                topicSection(title: "Strongest Topics", topics: overview.strongestTopics, accent: LumenColors.gradientStart)
                topicSection(title: "Weakest Topics", topics: overview.weakestTopics, accent: Color(red: 1.0, green: 0.58, blue: 0.36))
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
    }

    private func highlightCard(overview: ProgressOverview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current streak")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.74))

                    Text("\(overview.currentStreak) day\(overview.currentStreak == 1 ? "" : "s")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    scoreBadge(title: "Comprehension", score: overview.comprehensionScore)
                    scoreBadge(title: "Speaking", score: overview.speakingConfidenceScore)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weekly goal")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                    Spacer()
                    Text("\(overview.weeklyGoalProgress)/\(overview.weeklyGoalTarget)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                GeometryReader { geometry in
                    let progress = overview.weeklyGoalTarget > 0 ? min(CGFloat(overview.weeklyGoalProgress) / CGFloat(overview.weeklyGoalTarget), 1) : 0
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                        Capsule()
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 12)
            }

            Text("Week: \(overview.weekStartDate) to \(overview.weekEndDate)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.23, blue: 0.38),
                            Color(red: 0.18, green: 0.15, blue: 0.34)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func scoreBadge(title: String, score: Int?) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.66))
            Text(score.map { "\($0)" } ?? "--")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func statCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text(caption)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LumenColors.navyLight)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func topicSection(title: String, topics: [TopicPerformanceSummary], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            if topics.isEmpty {
                Text("Not enough topic data yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(LumenColors.textSecondary)
            } else {
                ForEach(topics) { topic in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(accent.opacity(0.22))
                            .overlay {
                                Circle()
                                    .fill(accent)
                                    .frame(width: 12, height: 12)
                            }
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(topic.topic)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("\(topic.meaningfulReelsCompleted) meaningful reels • comp \(topic.comprehensionScore.map(String.init) ?? "--") • speak \(topic.speakingScore.map(String.init) ?? "--")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LumenColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LumenColors.navyLight)
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProgressOverviewView(accessToken: "preview")
    }
}

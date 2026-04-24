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
        .onReceive(NotificationCenter.default.publisher(for: .progressOverviewShouldRefresh)) { _ in
            Task {
                await viewModel.refreshIfPossible()
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
                todayGoalCard(overview: overview)

                HStack(spacing: 14) {
                    statCard(title: LocalizedStrings.progressStudyDays, value: "\(overview.totalStudyDays)", caption: LocalizedStrings.progressAllTime)
                    statCard(title: LocalizedStrings.progressThisWeek, value: "\(overview.minutesStudiedThisWeek)m", caption: "\(overview.meaningfulReelsCompleted) \(LocalizedStrings.progressMeaningfulReels)")
                }

                HStack(spacing: 14) {
                    statCard(title: LocalizedStrings.progressReviews, value: "\(overview.reviewsCompleted)", caption: LocalizedStrings.progressCompletedThisWeek)
                    statCard(title: LocalizedStrings.progressSpeaking, value: "\(overview.speakingSessionsCompleted)", caption: LocalizedStrings.progressCompletedThisWeek)
                }

                statCard(title: LocalizedStrings.progressXP, value: "\(xpTracker.totalXP)", caption: LocalizedStrings.progressEarnedFromLearningActions)

                topicSection(title: LocalizedStrings.progressStrongestTopics, topics: overview.strongestTopics, accent: LumenColors.gradientStart)
                topicSection(title: LocalizedStrings.progressWeakestTopics, topics: overview.weakestTopics, accent: Color(red: 1.0, green: 0.58, blue: 0.36))
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
                    Text(LocalizedStrings.progressStreakLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.74))

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.67, blue: 0.30), Color(red: 1.0, green: 0.42, blue: 0.22)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("\(overview.currentStreak) \(overview.currentStreak == 1 ? LocalizedStrings.progressDay : LocalizedStrings.progressDays)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(streakSupportCopy(for: overview))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LumenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    scoreBadge(title: LocalizedStrings.progressComprehension, score: overview.comprehensionScore)
                    scoreBadge(title: LocalizedStrings.progressSpeaking, score: overview.speakingConfidenceScore)
                }
            }

            HStack(spacing: 12) {
                summaryPill(
                    title: LocalizedStrings.progressLongestStreak,
                    value: "\(overview.longestStreak)"
                )
                summaryPill(
                    title: LocalizedStrings.progressTodayStatus,
                    value: overview.todayStreakEligible ? LocalizedStrings.progressStreakAlive : LocalizedStrings.progressStreakKeepAlive
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(LocalizedStrings.progressWeeklyGoal)
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
                .frame(height: 10)
            }

            Text("\(LocalizedStrings.progressWeekRange): \(overview.weekStartDate) to \(overview.weekEndDate)")
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

    private func todayGoalCard(overview: ProgressOverview) -> some View {
        let target = overview.todayGoalTarget ?? overview.todayActivitySummary.goalTarget ?? 0
        let progress = overview.todayGoalProgress

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStrings.progressTodayGoal)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.74))

                    Text(target > 0 ? "\(progress) / \(target)" : "\(progress)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text(goalSupportCopy(for: overview))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LumenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text(overview.todayGoalCompleted ? LocalizedStrings.progressGoalCompleted : LocalizedStrings.progressGoalInProgress)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(overview.todayGoalCompleted ? Color.white : LumenColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(overview.todayGoalCompleted ? Color(red: 0.18, green: 0.53, blue: 0.42) : Color.white.opacity(0.08))
                    )
            }

            GeometryReader { geometry in
                let fraction = target > 0 ? min(CGFloat(progress) / CGFloat(target), 1) : 0
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: overview.todayGoalCompleted
                                    ? [Color(red: 0.24, green: 0.77, blue: 0.60), Color(red: 0.13, green: 0.67, blue: 0.51)]
                                    : [LumenColors.gradientStart, LumenColors.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * fraction)
                }
            }
            .frame(height: 12)

            HStack(spacing: 10) {
                todayMetricChip(title: LocalizedStrings.progressMeaningfulReels, value: "\(overview.todayMeaningfulReels)")
                todayMetricChip(title: LocalizedStrings.progressSpeaking, value: "\(overview.todaySpeakingCompleted)")
                todayMetricChip(title: LocalizedStrings.progressReviews, value: "\(overview.todayReviewActions)")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LumenColors.navyLight)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
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

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func todayMetricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.60))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func streakSupportCopy(for overview: ProgressOverview) -> String {
        if overview.currentStreak <= 0 {
            return LocalizedStrings.progressStreakKeepAlive
        }
        if overview.todayStreakEligible {
            return LocalizedStrings.progressStreakAlive
        }
        return LocalizedStrings.progressStreakKeepAlive
    }

    private func goalSupportCopy(for overview: ProgressOverview) -> String {
        if overview.todayGoalCompleted {
            return LocalizedStrings.progressGoalCompleted
        }
        if overview.todayStreakEligible {
            return LocalizedStrings.progressGoalMomentum
        }
        return LocalizedStrings.progressGoalKeepGoing
    }

    private func topicSection(title: String, topics: [TopicPerformanceSummary], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            if topics.isEmpty {
                Text(LocalizedStrings.progressNotEnoughTopicData)
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

                            Text("\(topic.meaningfulReelsCompleted) \(LocalizedStrings.progressMeaningfulReels) • \(LocalizedStrings.progressCompShort) \(topic.comprehensionScore.map(String.init) ?? "--") • \(LocalizedStrings.progressSpeakShort) \(topic.speakingScore.map(String.init) ?? "--")")
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

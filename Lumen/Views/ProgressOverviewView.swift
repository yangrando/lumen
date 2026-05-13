import SwiftUI

struct ProgressOverviewView: View {
    let accessToken: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProgressOverviewViewModel()
    @StateObject private var xpTracker = XPTracker.shared

    var body: some View {
        ZStack {
            LumenColors.ink900
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
                .font(LumenFont.grotesk(20, weight: .semibold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.progressLoadingDescription)
                .font(LumenFont.grotesk(14))
                .foregroundStyle(LumenColors.textSecondary)
        }
        .padding(.horizontal, 24)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(LumenFont.grotesk(42))
                .foregroundStyle(.white.opacity(0.88))

            Text(LocalizedStrings.progressErrorTitle)
                .font(LumenFont.grotesk(20, weight: .bold))
                .foregroundStyle(.white)

            Text(message)
                .font(LumenFont.grotesk(14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)

            LumenButton(kind: .primary, size: .md, isFullWidth: true, label: LocalizedStrings.commonRetry) {
                Task { await viewModel.load(accessToken: accessToken) }
            }
        }
        .padding(.horizontal, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(LumenFont.grotesk(42))
                .foregroundStyle(.white.opacity(0.88))

            Text(LocalizedStrings.progressEmptyTitle)
                .font(LumenFont.grotesk(20, weight: .bold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.progressEmptyDescription)
                .font(LumenFont.grotesk(14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    @State private var selectedPeriod = 0 // 0=7D, 1=30D, 2=ALL

    private func content(overview: ProgressOverview) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // ── Hero number (design: large avg score)
                heroScore(overview: overview)

                // ── Today's goal progress (ring-style card)
                todayGoalCard(overview: overview)

                // ── Stats grid (2 columns)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    statCard(title: LocalizedStrings.progressStudyDays, value: "\(overview.totalStudyDays)", caption: LocalizedStrings.progressAllTime)
                    statCard(title: LocalizedStrings.progressThisWeek, value: "\(overview.minutesStudiedThisWeek)m", caption: "\(overview.meaningfulReelsCompleted) \(LocalizedStrings.progressMeaningfulReels)")
                    statCard(title: LocalizedStrings.progressReviews, value: "\(overview.reviewsCompleted)", caption: LocalizedStrings.progressCompletedThisWeek)
                    statCard(title: LocalizedStrings.progressSpeaking, value: "\(overview.speakingSessionsCompleted)", caption: LocalizedStrings.progressCompletedThisWeek)
                }

                // ── XP card
                statCard(title: LocalizedStrings.progressXP, value: "\(xpTracker.totalXP)", caption: LocalizedStrings.progressEarnedFromLearningActions)

                // ── Skill breakdown (design-spec)
                skillBreakdown(overview: overview)

                // ── Topic sections
                topicSection(title: LocalizedStrings.progressStrongestTopics, topics: overview.strongestTopics, accent: LumenColors.gradientStart)
                topicSection(title: LocalizedStrings.progressWeakestTopics, topics: overview.weakestTopics, accent: LumenColors.warn)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
    }

    // MARK: — Hero score (design: large accent number)

    private func heroScore(overview: ProgressOverview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Period picker (7D / 30D / ALL)
            HStack {
                Text(LocalizedStrings.progressTitle)
                    .font(LumenFont.grotesk(22, weight: .semibold))
                    .foregroundStyle(LumenColors.ink50)

                Spacer()

                HStack(spacing: 2) {
                    ForEach(["7D", "30D", "ALL"].indices, id: \.self) { i in
                        let labels = ["7D", "30D", "ALL"]
                        Button {
                            selectedPeriod = i
                        } label: {
                            Text(labels[i])
                                .font(LumenFont.mono(9, weight: .medium))
                                .tracking(1.4)
                                .foregroundStyle(selectedPeriod == i ? LumenColors.ink900 : LumenColors.ink300)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(selectedPeriod == i ? LumenColors.accent : .clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(LumenColors.ink800)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(LumenColors.ink700, lineWidth: 1))
            }

            // Avg score
            Text("AVG SCORE · 7 DAYS")
                .font(LumenFont.mono(9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(LumenColors.ink400)

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("\(overview.comprehensionScore ?? 0)")
                        .font(LumenFont.grotesk(64, weight: .light))
                        .foregroundStyle(LumenColors.accent)
                        .kerning(-2)
                    Text("%")
                        .font(LumenFont.grotesk(24))
                        .foregroundStyle(LumenColors.ink400)
                }

                if overview.currentStreak > 0 {
                    Text("🔥 \(overview.currentStreak) day streak")
                        .font(LumenFont.mono(10, weight: .medium))
                        .tracking(1.0)
                        .foregroundStyle(LumenColors.good)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LumenColors.good.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: — Skill breakdown (design-spec rows)

    private func skillBreakdown(overview: ProgressOverview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SKILL BREAKDOWN")
                .font(LumenFont.mono(9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(LumenColors.ink400)

            let skills: [(String, Int?)] = [
                (LocalizedStrings.progressComprehension, overview.comprehensionScore),
                (LocalizedStrings.progressSpeaking, overview.speakingConfidenceScore),
            ]

            ForEach(skills, id: \.0) { name, score in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(name)
                            .font(LumenFont.grotesk(13, weight: .medium))
                            .foregroundStyle(LumenColors.ink50)
                        Spacer()
                        HStack(alignment: .lastTextBaseline, spacing: 1) {
                            Text(score.map(String.init) ?? "--")
                                .font(LumenFont.grotesk(14, weight: .semibold))
                                .foregroundStyle(LumenColors.ink50)
                            if score != nil {
                                Text("%")
                                    .font(LumenFont.mono(10))
                                    .foregroundStyle(LumenColors.ink400)
                            }
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(LumenColors.ink700)
                            Capsule()
                                .fill(LumenColors.accent)
                                .frame(width: geo.size.width * CGFloat(score ?? 0) / 100)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(LumenColors.ink800)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LumenColors.ink700, lineWidth: 1)
                }
            }
        }
    }

    private func highlightCard(overview: ProgressOverview) -> some View {
        EmptyView() // Replaced by heroScore() in content()
    }

    private func todayGoalCard(overview: ProgressOverview) -> some View {
        let target = overview.todayGoalTarget ?? overview.todayActivitySummary.goalTarget ?? 0
        let progress = overview.todayGoalProgress
        let pct: Double = target > 0 ? min(Double(progress) / Double(target) * 100, 100) : 0

        return HStack(spacing: 18) {
            // Progress ring (design-spec: 92px)
            LumenProgressRing(percent: pct, size: 92)

            VStack(alignment: .leading, spacing: 4) {
                Text("GOAL")
                    .font(LumenFont.mono(9, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(LumenColors.ink400)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(progress)")
                        .font(LumenFont.grotesk(28, weight: .medium))
                        .foregroundStyle(LumenColors.ink50)
                    if target > 0 {
                        Text("/ \(target)")
                            .font(LumenFont.grotesk(16))
                            .foregroundStyle(LumenColors.ink400)
                    }
                }

                Text(goalSupportCopy(for: overview))
                    .font(LumenFont.grotesk(12))
                    .foregroundStyle(LumenColors.ink300)
            }

            Spacer()

            if overview.todayGoalCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(LumenColors.good)
            }
        }
        .padding(18)
        .background(LumenColors.ink800)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }

    private func scoreBadge(title: String, score: Int?) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(title)
                .font(LumenFont.grotesk(12, weight: .medium))
                .foregroundStyle(.white.opacity(0.66))
            Text(score.map { "\($0)" } ?? "--")
                .font(LumenFont.grotesk(26, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func statCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(LumenFont.grotesk(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))

            Text(value)
                .font(LumenFont.grotesk(24, weight: .bold))
                .foregroundStyle(.white)

            Text(caption)
                .font(LumenFont.grotesk(12, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LumenColors.ink800)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LumenFont.grotesk(11, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))

            Text(value)
                .font(LumenFont.grotesk(14, weight: .semibold))
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
                .font(LumenFont.grotesk(11, weight: .medium))
                .foregroundStyle(.white.opacity(0.60))

            Text(value)
                .font(LumenFont.grotesk(16, weight: .bold))
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
                .font(LumenFont.grotesk(20, weight: .bold))
                .foregroundStyle(.white)

            if topics.isEmpty {
                Text(LocalizedStrings.progressNotEnoughTopicData)
                    .font(LumenFont.grotesk(14))
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
                                .font(LumenFont.grotesk(16, weight: .semibold))
                                .foregroundStyle(.white)

                            Text("\(topic.meaningfulReelsCompleted) \(LocalizedStrings.progressMeaningfulReels) • \(LocalizedStrings.progressCompShort) \(topic.comprehensionScore.map(String.init) ?? "--") • \(LocalizedStrings.progressSpeakShort) \(topic.speakingScore.map(String.init) ?? "--")")
                                .font(LumenFont.grotesk(13, weight: .medium))
                                .foregroundStyle(LumenColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LumenColors.ink800)
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

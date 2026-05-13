import SwiftUI

struct ReviewTodayView: View {
    let accessToken: String

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audioService = AudioService.shared
    @StateObject private var viewModel = ReviewTodayViewModel()
    @State private var speakingReviewItem: ReviewItem?

    var body: some View {
        ZStack {
            LumenColors.ink900
                .ignoresSafeArea()

            if viewModel.isLoading {
                loadingState
            } else if let errorMessage = viewModel.errorMessage, viewModel.response == nil {
                errorState(message: errorMessage)
            } else if let response = viewModel.response, response.hasItems {
                content(response: response)
            } else {
                emptyState
            }
        }
        .navigationTitle(LocalizedStrings.reviewTodayTitle)
        .appFeedbackBanner($viewModel.feedbackMessage)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            LumenNavigationBackButton {
                dismiss()
            }
        }
        .task {
            if viewModel.response == nil && !viewModel.isLoading {
                await viewModel.load(accessToken: accessToken)
            }
        }
        .sheet(item: $speakingReviewItem) { item in
            SpeakingPracticeView(
                title: LocalizedStrings.reviewTodaySpeakingReview,
                accessToken: accessToken,
                targetText: item.promptText,
                reelID: item.sourceReelID,
                reviewItemID: item.id,
                onAppearTrack: {
                    Task {
                        _ = await TrackingService.shared.startSession(.speaking, metadata: ["source": .string("review_speaking")])
                        await TrackingService.shared.track(
                            event: .speakingStarted,
                            reelID: item.sourceReelID,
                            sessionType: .speaking,
                            metadata: [
                                "surface": .string("review_today"),
                                "review_item_id": .int(item.id)
                            ]
                        )
                    }
                },
                onDisappearTrack: {
                    Task {
                        await TrackingService.shared.endSession(.speaking, metadata: ["reason": .string("speaking_review_closed")])
                    }
                },
                onCompleted: { attempt in
                    if attempt.reviewOutcome != nil {
                        viewModel.removeItemFromQueue(item.id)
                    }
                }
            )
        }
        .onAppear {
            Task {
                _ = await TrackingService.shared.startSession(.review, metadata: ["source": .string("review_today")])
            }
        }
        .onDisappear {
            audioService.stop()
            Task {
                await TrackingService.shared.endSession(.review, metadata: ["reason": .string("review_today_closed")])
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            Text(LocalizedStrings.reviewTodayLoadingTitle)
                .font(LumenFont.grotesk(20, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(LocalizedStrings.reviewTodayLoadingDescription)
                .font(LumenFont.grotesk(14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.clockwise.circle")
                .font(LumenFont.grotesk(42))
                .foregroundStyle(.white.opacity(0.86))

            Text(LocalizedStrings.reviewTodayErrorTitle)
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
            Image(systemName: "checkmark.circle")
                .font(LumenFont.grotesk(44))
                .foregroundStyle(.white.opacity(0.88))

            Text(LocalizedStrings.reviewTodayEmptyTitle)
                .font(LumenFont.grotesk(22, weight: .bold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.reviewTodayEmptyDescription)
                .font(LumenFont.grotesk(14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    private func content(response: ReviewTodayResponse) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Design-spec header: title + goal ring card
                dailyReviewHeader(response: response)

                // All items grouped by review type
                ForEach(response.groups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(displayTitle(for: group.reviewType).uppercased()) · \(group.items.count)")
                                .font(LumenFont.mono(9, weight: .medium))
                                .tracking(1.4)
                                .foregroundStyle(LumenColors.ink400)
                            Spacer()
                        }

                        ForEach(group.items) { item in
                            reviewCard(item)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
    }

    // MARK: — Daily review header (design-spec)

    private func dailyReviewHeader(response: ReviewTodayResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // "● TODAY" + streak
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LumenColors.accent)
                        .frame(width: 8, height: 8)
                    Text("TODAY")
                        .font(LumenFont.mono(10, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(LumenColors.accent)
                }
                Spacer()
                Text("\(response.totalDueCount) ITEMS DUE")
                    .font(LumenFont.mono(10, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(LumenColors.ink400)
            }

            // "Daily review." title — italic accent for "review"
            (
                Text("Daily ")
                    .font(LumenFont.grotesk(32, weight: .medium))
                    .foregroundStyle(LumenColors.ink50)
                + Text("review")
                    .font(LumenFont.serifItalic(32))
                    .foregroundStyle(LumenColors.accent)
                + Text(".")
                    .font(LumenFont.grotesk(32, weight: .medium))
                    .foregroundStyle(LumenColors.ink50)
            )
            .kerning(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            // Goal ring card
            HStack(spacing: 18) {
                LumenProgressRing(
                    percent: goalProgress(response: response) * 100,
                    size: 92
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("GOAL")
                        .font(LumenFont.mono(9, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(LumenColors.ink400)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(response.totalDueCount)")
                            .font(LumenFont.grotesk(28, weight: .medium))
                            .foregroundStyle(LumenColors.ink50)
                        Text("items")
                            .font(LumenFont.grotesk(16))
                            .foregroundStyle(LumenColors.ink400)
                    }

                    Text("due today")
                        .font(LumenFont.grotesk(12))
                        .foregroundStyle(LumenColors.ink300)
                }
                Spacer()
            }
            .padding(18)
            .background(LumenColors.ink800)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LumenColors.ink700, lineWidth: 1)
            }
        }
    }

    private func goalProgress(response: ReviewTodayResponse) -> Double {
        let total = response.totalDueCount
        guard total > 0 else { return 1.0 }
        // Show progress based on items completed (submitted)
        let remaining = response.groups.flatMap(\.items).count
        let done = max(0, total - remaining)
        return min(Double(done) / Double(total), 1.0)
    }


    private func reviewCard(_ item: ReviewItem) -> some View {
        HStack(spacing: 0) {
            // Colored left border strip (design spec)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(itemAccentColor(item))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayTitle(for: item.reviewType).uppercased())
                            .font(LumenFont.mono(9, weight: .medium))
                            .tracking(1.4)
                            .foregroundStyle(LumenColors.ink400)

                        Text(item.promptText)
                            .font(LumenFont.grotesk(13, weight: .medium))
                            .foregroundStyle(LumenColors.ink50)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                if let translation = item.translation, !translation.isEmpty {
                    Text(translation)
                        .font(LumenFont.grotesk(12))
                        .foregroundStyle(LumenColors.ink400)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let explanation = item.explanation, !explanation.isEmpty {
                    Text(explanation)
                        .font(LumenFont.grotesk(12))
                        .foregroundStyle(LumenColors.ink400)
                        .lineLimit(2)
                }

                if item.overdueDays > 0 {
                    Text(LocalizedStrings.reviewOverdueDays(item.overdueDays))
                        .font(LumenFont.mono(9, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(LumenColors.ink400)
                }

                if item.reviewType == "speaking_review" {
                    LumenButton(
                        kind: .primary, size: .sm,
                        isFullWidth: true,
                        label: LocalizedStrings.reviewTodayPracticeSpeaking,
                        icon: Image(systemName: "mic.fill")
                    ) {
                        speakingReviewItem = item
                    }
                } else {
                    HStack(spacing: 8) {
                        // Listen button
                        let audioID = reviewAudioID(for: item)
                        Button {
                            audioService.togglePlayback(for: audioID, text: item.promptText)
                        } label: {
                            Image(systemName: audioService.currentlyPlayingPhraseID == audioID ? "stop.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(LumenColors.ink100)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(LumenColors.ink700, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        ForEach(ReviewResultValue.allCases) { result in
                            Button {
                                Task { await viewModel.submit(accessToken: accessToken, item: item, result: result) }
                            } label: {
                                Text(result.title)
                                    .font(LumenFont.grotesk(12, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(buttonBackground(for: result))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.submittingItemIDs.contains(item.id))
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(LumenColors.ink800)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }

    private func itemAccentColor(_ item: ReviewItem) -> Color {
        switch item.lastResult?.lowercased() {
        case "failed":        return LumenColors.bad
        case "hard":          return LumenColors.warn
        case "medium":        return LumenColors.info
        case "easy":          return LumenColors.good
        default:              return LumenColors.warn
        }
    }

    private func buttonBackground(for result: ReviewResultValue) -> Color {
        switch result {
        case .failed:
            return LumenColors.bad.opacity(0.5)
        case .hard:
            return LumenColors.warn.opacity(0.4)
        case .medium:
            return LumenColors.info.opacity(0.35)
        case .easy:
            return LumenColors.good.opacity(0.35)
        }
    }

    private func displayTitle(for reviewType: String) -> String {
        switch reviewType {
        case "quick_review":       return LocalizedStrings.reviewTypeQuick
        case "speaking_review":    return LocalizedStrings.reviewTypeSpeaking
        case "saved_review":       return LocalizedStrings.reviewTypeSaved
        case "vocabulary_review":  return LocalizedStrings.reviewTypeVocabulary
        case "contextual_review":  return LocalizedStrings.reviewTypeContextual
        default:                   return reviewType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func reviewAudioID(for item: ReviewItem) -> UUID {
        UUID(uuidString: ReviewUUIDv5.make(namespace: ReviewUUIDv5.namespaceDNS, name: "review-\(item.id)")) ?? UUID()
    }
}

#Preview {
    NavigationStack {
        ReviewTodayView(accessToken: "preview")
    }
}

private enum ReviewUUIDv5 {
    static let namespaceDNS = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"

    static func make(namespace: String, name: String) -> String {
        let input = "\(namespace)\(name)"
        let hash = Array(input.utf8).reduce(into: [UInt8](repeating: 0, count: 16)) { result, byte in
            let idx = Int(byte) % 16
            result[idx] ^= byte
        }

        var bytes = hash
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20).prefix(12))"
    }
}

import SwiftUI

struct ReviewTodayView: View {
    let accessToken: String

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audioService = AudioService.shared
    @StateObject private var viewModel = ReviewTodayViewModel()
    @State private var speakingReviewItem: ReviewItem?

    var body: some View {
        ZStack {
            LumenColors.navyDark
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
        .navigationTitle("Review Today")
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
                title: "Speaking Review",
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
                await TrackingService.shared.startSession(.review, metadata: ["source": .string("review_today")])
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
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(LocalizedStrings.reviewTodayLoadingDescription)
                .font(.system(size: 14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.86))

            Text(LocalizedStrings.reviewTodayErrorTitle)
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
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.88))

            Text(LocalizedStrings.reviewTodayEmptyTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.reviewTodayEmptyDescription)
                .font(.system(size: 14))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    private func content(response: ReviewTodayResponse) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerCard(response: response)

                ForEach(response.groups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(displayTitle(for: group.reviewType))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)

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

    private func headerCard(response: ReviewTodayResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStrings.reviewTodayTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.70))

            Text("\(response.totalDueCount) item\(response.totalDueCount == 1 ? "" : "s")")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)

            if let generated = response.generatedToday["total"] {
                Text("Generated or reused \(generated) review candidates for today.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LumenColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.24, blue: 0.40),
                            Color(red: 0.20, green: 0.16, blue: 0.36)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private func reviewCard(_ item: ReviewItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayTitle(for: item.reviewType))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LumenColors.gradientStart)

                    Text(item.promptText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                let audioID = reviewAudioID(for: item)
                Button {
                    audioService.togglePlayback(for: audioID, text: item.promptText)
                } label: {
                    Image(systemName: audioService.currentlyPlayingPhraseID == audioID ? "stop.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if let translation = item.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LumenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let explanation = item.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                if let topic = item.topic, !topic.isEmpty {
                    tag(topic)
                }
                if let difficulty = item.difficulty, !difficulty.isEmpty {
                    tag(difficulty)
                }
                if item.overdueDays > 0 {
                    tag("\(item.overdueDays)d overdue")
                }
            }

            if item.reviewType == "speaking_review" {
                Button {
                    speakingReviewItem = item
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                        Text("Practice speaking")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 8) {
                    ForEach(ReviewResultValue.allCases) { result in
                        Button {
                            Task {
                                await viewModel.submit(accessToken: accessToken, item: item, result: result)
                            }
                        } label: {
                            Text(result.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(buttonBackground(for: result))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.submittingItemIDs.contains(item.id))
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LumenColors.navyLight)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.84))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }

    private func buttonBackground(for result: ReviewResultValue) -> Color {
        switch result {
        case .failed:
            return Color(red: 0.58, green: 0.18, blue: 0.24)
        case .hard:
            return Color(red: 0.65, green: 0.39, blue: 0.16)
        case .medium:
            return Color(red: 0.24, green: 0.40, blue: 0.62)
        case .easy:
            return Color(red: 0.20, green: 0.52, blue: 0.43)
        }
    }

    private func displayTitle(for reviewType: String) -> String {
        switch reviewType {
        case "quick_review":
            return "Quick Review"
        case "speaking_review":
            return "Speaking Review"
        case "saved_review":
            return "Saved Review"
        case "vocabulary_review":
            return "Vocabulary Review"
        case "contextual_review":
            return "Contextual Review"
        default:
            return reviewType.replacingOccurrences(of: "_", with: " ").capitalized
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

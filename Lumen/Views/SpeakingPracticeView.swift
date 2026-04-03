import SwiftUI
import Foundation

struct SpeakingPracticeView: View {
    let title: String
    let accessToken: String
    let targetText: String
    let reelID: String?
    let reviewItemID: Int?
    let onAppearTrack: (() -> Void)?
    let onDisappearTrack: (() -> Void)?
    let onCompleted: ((SpeakingAttempt) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audioService = AudioService.shared
    @StateObject private var viewModel: SpeakingPracticeViewModel

    init(
        title: String = "Speaking Practice",
        accessToken: String,
        targetText: String,
        reelID: String?,
        reviewItemID: Int?,
        onAppearTrack: (() -> Void)? = nil,
        onDisappearTrack: (() -> Void)? = nil,
        onCompleted: ((SpeakingAttempt) -> Void)? = nil
    ) {
        self.title = title
        self.accessToken = accessToken
        self.targetText = targetText
        self.reelID = reelID
        self.reviewItemID = reviewItemID
        self.onAppearTrack = onAppearTrack
        self.onDisappearTrack = onDisappearTrack
        self.onCompleted = onCompleted
        _viewModel = StateObject(
            wrappedValue: SpeakingPracticeViewModel(
                accessToken: accessToken,
                targetText: targetText,
                reelID: reelID,
                reviewItemID: reviewItemID
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumenColors.navyDark
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        targetCard
                        controlsCard

                        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                            errorCard(message: errorMessage)
                        }

                        if let attempt = viewModel.attempt {
                            resultCard(attempt: attempt)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                LumenNavigationBackButton {
                    viewModel.cancelRecording()
                    dismiss()
                }
            }
            .onAppear {
                onAppearTrack?()
            }
            .onDisappear {
                audioService.stop()
                viewModel.cancelRecording()
                onDisappearTrack?()
            }
        }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat exactly")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LumenColors.gradientStart)

            Text(targetText)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Listen first if you want, then record your voice repeating the same sentence.")
                .font(.system(size: 14))
                .foregroundStyle(LumenColors.textSecondary)

            Button {
                let audioID = UUID(uuidString: speakingAudioID(for: targetText)) ?? UUID()
                audioService.togglePlayback(for: audioID, text: targetText)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Listen to target")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(Color.white.opacity(0.10))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LumenColors.navyLight)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(viewModel.isRecording ? "Recording..." : (viewModel.isUploading ? "Analyzing..." : "Ready to practice"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(timeString(from: viewModel.elapsedSeconds))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LumenColors.textSecondary)
            }

            if viewModel.isUploading {
                ProgressView()
                    .tint(.white)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        audioService.stop()
                        if viewModel.isRecording {
                            if let response = await viewModel.stopAndSubmit() {
                                onCompleted?(response)
                            }
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        Text(viewModel.isRecording ? "Stop and submit" : "Start recording")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isUploading)

                Button {
                    viewModel.retry()
                } label: {
                    Text("Retry")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 92, height: 54)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRecording || viewModel.isUploading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LumenColors.navyLight)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private func resultCard(attempt: SpeakingAttempt) -> some View {
        let summary = SpeakingFeedbackService.summary(for: attempt)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pronunciation Score")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LumenColors.textSecondary)

                    Text("\(attempt.score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(summary.scoreColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Similarity")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LumenColors.textSecondary)

                    Text("\(attempt.similarityScore)%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(summary.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(summary.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LumenColors.textSecondary)
            }

            if let transcript = attempt.transcript, !transcript.isEmpty {
                detailBlock(title: "You said", value: transcript)
            }

            if !attempt.missingWords.isEmpty {
                detailBlock(title: "Missing words", value: attempt.missingWords.joined(separator: ", "))
            }

            if !attempt.incorrectWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pronunciation differences")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LumenColors.textSecondary)

                    ForEach(attempt.incorrectWords.prefix(3)) { pair in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You said: \"\(pair.heard)\"")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(red: 1.0, green: 0.63, blue: 0.25))
                            Text("Expected: \"\(pair.expected)\"")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(red: 0.42, green: 0.88, blue: 0.99))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }

            detailBlock(title: "Feedback", value: attempt.feedback)

            Text(attempt.recommendation == "good_job" ? "Good job" : "Try again")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.10))
                .clipShape(Capsule())
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

    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LumenColors.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func errorCard(message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.red.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func timeString(from duration: TimeInterval) -> String {
        let seconds = max(Int(duration.rounded()), 0)
        return String(format: "%01d:%02d", seconds / 60, seconds % 60)
    }

    private func speakingAudioID(for name: String) -> String {
        let input = "speaking-\(name)"
        var hash = Array(input.utf8).reduce(into: [UInt8](repeating: 0, count: 16)) { result, byte in
            let idx = Int(byte) % 16
            result[idx] ^= byte
            result[(idx + 5) % 16] = result[(idx + 5) % 16] &+ byte
        }
        hash[6] = (hash[6] & 0x0F) | 0x50
        hash[8] = (hash[8] & 0x3F) | 0x80
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        return [
            String(hex.prefix(8)),
            String(hex.dropFirst(8).prefix(4)),
            String(hex.dropFirst(12).prefix(4)),
            String(hex.dropFirst(16).prefix(4)),
            String(hex.dropFirst(20).prefix(12))
        ].joined(separator: "-")
    }
}

#Preview {
    SpeakingPracticeView(
        accessToken: "preview",
        targetText: "I have been looking forward to this trip for months.",
        reelID: "reel-preview",
        reviewItemID: nil
    )
}

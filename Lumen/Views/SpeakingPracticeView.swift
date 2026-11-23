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
        title: String = LocalizedStrings.progressSpeaking,
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
                LumenColors.ink900
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        phraseCard
                        controlsCard

                        if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                            errorBanner(message: errorMessage)
                        }

                        if let attempt = viewModel.attempt {
                            resultCard(attempt: attempt)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
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
            .onAppear { onAppearTrack?() }
            .onDisappear {
                audioService.stop()
                viewModel.cancelRecording()
                onDisappearTrack?()
            }
        }
    }

    // MARK: – Phrase card

    private var phraseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LocalizedStrings.speakingPracticeRepeatExactly.uppercased())
                .font(LumenFont.mono(10, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(LumenColors.accent)

            Text(targetText)
                .font(LumenFont.grotesk(22, weight: .bold))
                .foregroundStyle(LumenColors.ink50)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStrings.speakingPracticeInstruction)
                .font(LumenFont.grotesk(13))
                .foregroundStyle(LumenColors.ink300)
                .fixedSize(horizontal: false, vertical: true)

            // Listen button
            let audioID = UUID(uuidString: speakingAudioID(for: targetText)) ?? UUID()
            Button {
                audioService.togglePlayback(for: audioID, text: targetText)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: audioService.currentlyPlayingPhraseID == audioID
                          ? "stop.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(LocalizedStrings.speakingPracticeListenToTarget)
                        .font(LumenFont.grotesk(13, weight: .medium))
                }
                .foregroundStyle(LumenColors.ink50)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(LumenColors.ink700)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(LumenColors.ink600, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRecording || viewModel.isUploading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LumenColors.ink800)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }

    // MARK: – Controls card

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(controlsStatusLabel.uppercased())
                        .font(LumenFont.mono(9, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(viewModel.isRecording ? LumenColors.accent : LumenColors.ink400)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)

                    Text(controlsStatusHeadline)
                        .font(LumenFont.grotesk(18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.analysisPhase)
                }
                Spacer()
                if viewModel.isRecording || viewModel.elapsedSeconds > 0 && !viewModel.isUploading {
                    Text(timeString(from: viewModel.elapsedSeconds))
                        .font(LumenFont.mono(16, weight: .medium))
                        .foregroundStyle(viewModel.isRecording ? LumenColors.accent : LumenColors.ink400)
                        .monospacedDigit()
                }
            }

            // Waveform (recording) or progress indicator (uploading)
            if viewModel.isRecording {
                waveformBars
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if viewModel.isUploading || viewModel.analysisPhase == .retrying {
                uploadingIndicator
                    .transition(.opacity)
            }

            // Primary CTA
            LumenButton(
                kind: .primary, size: .lg,
                isDisabled: viewModel.isUploading,
                isFullWidth: true,
                label: primaryButtonLabel,
                icon: Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
            ) {
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
            }

            // Retry (hidden while recording/uploading)
            if !viewModel.isRecording && !viewModel.isUploading {
                LumenButton(
                    kind: .text,
                    isDisabled: false,
                    isFullWidth: true,
                    label: LocalizedStrings.speakingPracticeRetry
                ) {
                    viewModel.retry()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LumenColors.ink800)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isRecording)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isUploading)
    }

    // MARK: – Waveform bars (live level-driven)

    private var waveformBars: some View {
        let level = viewModel.recordingService.normalizedLevel
        return HStack(spacing: 3) {
            ForEach(0..<24, id: \.self) { i in
                Capsule()
                    .fill(LumenColors.accent.opacity(0.85))
                    .frame(width: 3, height: barHeight(index: i, level: level))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 44)
        .animation(.spring(response: 0.18, dampingFraction: 0.65), value: level)
    }

    private func barHeight(index: Int, level: Float) -> CGFloat {
        // Bell-curve envelope so centre bars are tallest
        let centre = 11.5
        let dist = abs(Double(index) - centre)
        let envelope = max(0, 1 - dist / 13.0)
        let noise = Double((index * 37 + Int(level * 100)) % 7) / 40.0
        let height = (Double(level) * 0.75 + noise) * 38.0 * envelope + 4.0
        return max(4, CGFloat(height))
    }

    // MARK: – Uploading indicator

    private var uploadingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(viewModel.analysisPhase == .retrying ? LumenColors.warn : LumenColors.accent)
                .scaleEffect(0.85)

            Text(indicatorLabel)
                .font(LumenFont.grotesk(13))
                .foregroundStyle(viewModel.analysisPhase == .retrying ? LumenColors.warn : LumenColors.ink300)
                .animation(.easeInOut, value: viewModel.analysisPhase)
        }
    }

    private var indicatorLabel: String {
        switch viewModel.analysisPhase {
        case .analyzing: return LocalizedStrings.speakingPracticeAnalyzing
        case .retrying:  return LocalizedStrings.speakingPracticeRetrying
        default:         return LocalizedStrings.speakingPracticeUploading
        }
    }

    // MARK: – Error banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LumenColors.bad)

            Text(message)
                .font(LumenFont.grotesk(13, weight: .medium))
                .foregroundStyle(LumenColors.ink50)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(LumenColors.bad.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LumenColors.bad.opacity(0.25), lineWidth: 1)
        }
    }

    // MARK: – Result card

    private func resultCard(attempt: SpeakingAttempt) -> some View {
        let summary = SpeakingFeedbackService.summary(for: attempt)
        return VStack(alignment: .leading, spacing: 16) {
            // Score row
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStrings.speakingPracticeScore.uppercased())
                        .font(LumenFont.mono(9, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(LumenColors.ink400)

                    Text("\(attempt.score)")
                        .font(LumenFont.grotesk(48, weight: .medium))
                        .foregroundStyle(summary.scoreColor)
                        .kerning(-1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(LocalizedStrings.speakingPracticeSimilarity.uppercased())
                        .font(LumenFont.mono(9, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(LumenColors.ink400)

                    Text("\(attempt.similarityScore)%")
                        .font(LumenFont.grotesk(32, weight: .medium))
                        .foregroundStyle(LumenColors.ink50)
                }
            }

            Divider().background(LumenColors.ink700)

            // Feedback headline
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.title)
                    .font(LumenFont.grotesk(16, weight: .semibold))
                    .foregroundStyle(LumenColors.ink50)
                Text(summary.subtitle)
                    .font(LumenFont.grotesk(13))
                    .foregroundStyle(LumenColors.ink300)
            }

            // Transcript
            if let transcript = attempt.transcript, !transcript.isEmpty {
                resultBlock(label: LocalizedStrings.speakingPracticeYouSaid, value: transcript)
            }

            // Missing words
            if !attempt.missingWords.isEmpty {
                resultBlock(
                    label: LocalizedStrings.speakingPracticeMissingWords,
                    value: attempt.missingWords.joined(separator: " · ")
                )
            }

            // Pronunciation differences
            if !attempt.incorrectWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.speakingPracticePronunciationDifferences.uppercased())
                        .font(LumenFont.mono(9, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(LumenColors.ink400)

                    ForEach(attempt.incorrectWords.prefix(3)) { pair in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStrings.speakingPracticeYouSaidLabel)
                                    .font(LumenFont.mono(8, weight: .medium))
                                    .tracking(1.2)
                                    .foregroundStyle(LumenColors.warn.opacity(0.7))
                                Text("\"\(pair.heard)\"")
                                    .font(LumenFont.grotesk(14, weight: .medium))
                                    .foregroundStyle(LumenColors.warn)
                            }
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LumenColors.ink500)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStrings.speakingPracticeExpectedLabel)
                                    .font(LumenFont.mono(8, weight: .medium))
                                    .tracking(1.2)
                                    .foregroundStyle(LumenColors.accent.opacity(0.7))
                                Text("\"\(pair.expected)\"")
                                    .font(LumenFont.grotesk(14, weight: .semibold))
                                    .foregroundStyle(LumenColors.accent)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LumenColors.ink700.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

            // Server feedback text
            resultBlock(label: LocalizedStrings.speakingPracticeFeedback, value: attempt.feedback)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LumenColors.ink800)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }

    private func resultBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(LumenFont.mono(9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(LumenColors.ink400)
            Text(value)
                .font(LumenFont.grotesk(14, weight: .medium))
                .foregroundStyle(LumenColors.ink50)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: – Helpers

    private var controlsStatusLabel: String {
        switch viewModel.analysisPhase {
        case .idle:      return viewModel.isRecording ? "REC" : "PRONTO"
        case .uploading: return "ENVIANDO"
        case .analyzing: return "ANALISANDO"
        case .retrying:  return "AGUARDE"
        }
    }

    private var controlsStatusHeadline: String {
        if viewModel.isRecording { return LocalizedStrings.speakingPracticeRecording }
        switch viewModel.analysisPhase {
        case .idle:      return LocalizedStrings.speakingPracticeReady
        case .uploading: return LocalizedStrings.speakingPracticeUploading
        case .analyzing: return LocalizedStrings.speakingPracticeAnalyzing
        case .retrying:  return LocalizedStrings.speakingPracticeRetrying
        }
    }

    private var primaryButtonLabel: String {
        viewModel.isRecording
            ? LocalizedStrings.speakingPracticeStopAndSubmit
            : LocalizedStrings.speakingPracticeStartRecording
    }

    private func timeString(from duration: TimeInterval) -> String {
        let s = max(Int(duration.rounded()), 0)
        return String(format: "%d:%02d", s / 60, s % 60)
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
        targetText: "We canceled the meeting because the client wasn't available, so we rescheduled it for next week.",
        reelID: "reel-preview",
        reviewItemID: nil
    )
}

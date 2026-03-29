import SwiftUI

struct AskAIView: View {
    let phrase: EnglishPhrase
    let onAsk: (String) async -> String
    let onOpen: (() -> Void)?
    let onSubmitQuestion: ((String) -> Void)?
    let onSpeakingStarted: (() -> Void)?
    let onSpeakingCompleted: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = SpeechToTextService()
    @State private var question = ""
    @State private var answer = ""
    @State private var isLoading = false
    @State private var validationError: String?
    @State private var hasReportedSpeakingCompletion = false

    var body: some View {
        NavigationStack {
            ZStack {
                LumenColors.navyDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStrings.askAITitle)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        Text(LocalizedStrings.askAISubtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(LumenColors.textSecondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(phrase.text)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        ZStack(alignment: .topLeading) {
                            if question.isEmpty {
                                Text(LocalizedStrings.askAIPlaceholder)
                                    .font(.system(size: 16))
                                    .foregroundStyle(LumenColors.textSecondary)
                                    .padding(.top, 12)
                                    .padding(.leading, 10)
                            }
                            TextEditor(text: $question)
                                .frame(minHeight: 120)
                                .padding(6)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(.white)
                                .background(Color.clear)
                        }
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 10) {
                            Button {
                                Task {
                                    let result = await speechService.toggleRecording()
                                    switch result {
                                    case .started:
                                        hasReportedSpeakingCompletion = false
                                        onSpeakingStarted?()
                                    case .stopped:
                                        if !hasReportedSpeakingCompletion {
                                            hasReportedSpeakingCompletion = true
                                            onSpeakingCompleted?(speechService.transcript)
                                        }
                                    case .failed:
                                        break
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: speechService.isRecording ? "stop.circle.fill" : "mic.fill")
                                    Text(speechService.isRecording ? LocalizedStrings.askAIStopRecord : LocalizedStrings.askAIRecord)
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .frame(height: 42)
                                .foregroundStyle(.white)
                                .background(Color.white.opacity(0.16))
                                .clipShape(Capsule())
                            }

                            Button {
                                Task { await ask() }
                            } label: {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text(isLoading ? LocalizedStrings.askAIThinking : LocalizedStrings.askAISend)
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 14)
                                .frame(height: 42)
                                .foregroundStyle(.white)
                                .background(LinearGradient.primaryGradient)
                                .clipShape(Capsule())
                            }
                            .disabled(isLoading)
                        }

                        if let validationError, !validationError.isEmpty {
                            Text(validationError)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red.opacity(0.95))
                        }

                        if let speechError = speechService.errorMessage, !speechError.isEmpty {
                            Text(speechError)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red.opacity(0.95))
                        }

                        if !answer.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(LocalizedStrings.feedAIFeedback)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)

                                Text(answer)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                onOpen?()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStrings.commonClose) {
                        if speechService.isRecording {
                            speechService.stopRecording()
                            if !hasReportedSpeakingCompletion {
                                hasReportedSpeakingCompletion = true
                                onSpeakingCompleted?(speechService.transcript)
                            }
                        } else if !hasReportedSpeakingCompletion,
                                  !speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            hasReportedSpeakingCompletion = true
                            onSpeakingCompleted?(speechService.transcript)
                        }
                        speechService.stopRecording()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onChange(of: speechService.transcript) { _, value in
                guard !value.isEmpty else { return }
                question = value
            }
        }
    }

    private func ask() async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = LocalizedStrings.askAIQuestionRequired
            return
        }

        validationError = nil
        isLoading = true
        onSubmitQuestion?(trimmed)
        answer = await onAsk(trimmed)
        isLoading = false
    }
}

#Preview {
    AskAIView(
        phrase: EnglishPhrase.mockPhrases[0],
        onAsk: { _ in "Example answer." },
        onOpen: nil,
        onSubmitQuestion: nil,
        onSpeakingStarted: nil,
        onSpeakingCompleted: nil
    )
}

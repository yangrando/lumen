import SwiftUI
import SwiftData

struct WordDetailSheet: View {
    let detail: WordDetail
    let userID: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedWord.createdAt, order: .reverse) private var savedWords: [SavedWord]
    @ObservedObject private var audioService = AudioService.shared
    @State private var feedbackMessage: AppFeedbackMessage?

    private var isSaved: Bool {
        savedWords.contains {
            $0.word.caseInsensitiveCompare(detail.word) == .orderedSame &&
            ($0.userID ?? "") == (userID ?? "")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LumenColors.navyDark.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(detail.word)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text(detail.phonetic)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LumenColors.gradientStart)
                        Text(detail.translation)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(LumenColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Example")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LumenColors.textSecondary)
                        Text(detail.exampleSentence)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 12) {
                        Button {
                            saveWord()
                        } label: {
                            Text(isSaved ? "Saved" : "Save word")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(LinearGradient.primaryGradient)
                                .clipShape(Capsule())
                        }

                        Button {
                            let audioID = UUID(uuidString: speakingAudioID(for: detail.word)) ?? UUID()
                            audioService.togglePlayback(for: audioID, text: detail.word)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "speaker.wave.2.fill")
                                Text("Hear pronunciation")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Capsule())
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Word details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                LumenNavigationBackButton {
                    dismiss()
                }
            }
            .appFeedbackBanner($feedbackMessage)
        }
    }

    private func saveWord() {
        guard !isSaved else { return }
        modelContext.insert(
            SavedWord(
                userID: userID,
                word: detail.word,
                phonetic: detail.phonetic,
                translation: detail.translation,
                exampleSentence: detail.exampleSentence
            )
        )
        try? modelContext.save()
        feedbackMessage = AppFeedbackMessage(
            title: LocalizedStrings.feedbackSuccessTitle,
            message: NativeLanguageLocalization.localizedString(forKey: "word.saved.success", fallback: "Word saved successfully."),
            tone: .success
        )
    }

    private func speakingAudioID(for name: String) -> String {
        let input = "word-\(name)"
        let hash = Array(input.utf8).reduce(into: [UInt8](repeating: 0, count: 16)) { result, byte in
            let idx = Int(byte) % 16
            result[idx] ^= byte
            result[(idx + 5) % 16] = result[(idx + 5) % 16] &+ byte
        }
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

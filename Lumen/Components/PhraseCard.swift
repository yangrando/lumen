import SwiftUI
import UIKit
import Foundation

struct PhraseCard: View {
    let phrase: EnglishPhrase
    let backgroundImageURL: URL?
    let isSaved: Bool
    let isAudioPlaying: Bool
    let learningState: ReelLearningState
    let highlightedTokens: [HighlightedWord]
    let currentUserID: String?
    @State private var isTranslationVisible = false
    @State private var localIsSaved = false
    @State private var selectedWordDetail: WordDetail?
    let onPlayAudio: () -> Void
    let onSpeak: () -> Void
    let onTranslationOpened: () -> Void
    let onAskAI: () -> Void
    let onSave: () -> Void

    private enum EditorialStyle {
        case glass
        case subtleGlass
    }
    
    var body: some View {
        GeometryReader { geometry in
            let horizontalMargin = max(20, geometry.safeAreaInsets.leading + 20)
            let trailingMargin = max(20, geometry.safeAreaInsets.trailing + 20)
            let topMargin: CGFloat = 52
            let bottomMenuBottomSpacing: CGFloat = 30
            let bottomMenuHeight: CGFloat = 50
            let saveBottomMargin = geometry.safeAreaInsets.bottom + bottomMenuBottomSpacing + bottomMenuHeight + 4

            ZStack {
                DynamicReelBackground(
                    category: phrase.category,
                    difficulty: phrase.difficulty,
                    seed: phrase.id.uuidString + phrase.text
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()

                if let backgroundImageURL {
                    AsyncImage(url: backgroundImageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(1.03)
                                .saturation(0.92)
                                .contrast(0.96)
                                .brightness(-0.02)
                                .opacity(0.88)
                                .transition(.opacity)
                        default:
                            Color.clear
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.42),
                        Color.black.opacity(0.10),
                        Color.black.opacity(0.38)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        ReelProgressIndicator(state: learningState)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 2)

                        subjectBadge
                            .frame(maxWidth: .infinity, alignment: .leading)

                        phraseTextBlock(in: geometry.size)

                        if isTranslationVisible {
                            translationText
                        }

                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 28)
                }
            }
            .overlay(alignment: .topTrailing) {
                HStack(alignment: .top, spacing: 10) {
                    topActionButton(
                        icon: isAudioPlaying ? "stop.fill" : "speaker.wave.2.fill",
                        title: isAudioPlaying ? LocalizedStrings.feedStopAudio : LocalizedStrings.feedListen,
                        action: onPlayAudio
                    )
                    topActionButton(
                        icon: "translate",
                        title: LocalizedStrings.feedTranslate,
                        action: {
                            let wasVisible = isTranslationVisible
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isTranslationVisible.toggle()
                            }
                            if !wasVisible {
                                onTranslationOpened()
                            }
                        }
                    )
                    topActionButton(
                        icon: "mic.fill",
                        title: "Speak",
                        action: onSpeak
                    )
                    topActionButton(
                        icon: "sparkles",
                        title: LocalizedStrings.feedAskAI,
                        isPrimary: true,
                        action: onAskAI
                    )
                }
                .padding(.trailing, trailingMargin)
                .padding(.top, topMargin)
            }
            .overlay(alignment: .bottomTrailing) {
                saveButton
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height, alignment: .bottomTrailing)
                    .padding(.trailing, trailingMargin)
                    .padding(.bottom, saveBottomMargin)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear {
            localIsSaved = isSaved
        }
        .onChange(of: isSaved) { _, newValue in
            localIsSaved = newValue
        }
        .sheet(item: $selectedWordDetail) { detail in
            WordDetailSheet(detail: detail, userID: currentUserID)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var editorialStyle: EditorialStyle {
        let key = phrase.category.lowercased()
        if key.contains("business") || key.contains("econom") || key.contains("finance") {
            return .subtleGlass
        }
        return .glass
    }

    private var topicBadge: some View {
        Text("\(phrase.category) • \(phrase.difficulty.rawValue)")
            .font(.custom("AvenirNext-Bold", size: 12))
            .foregroundStyle(Color(red: 0.19, green: 0.84, blue: 0.98))
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color(red: 0.09, green: 0.16, blue: 0.27).opacity(editorialStyle == .glass ? 0.78 : 0.88))
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
    }

    private var subjectBadge: some View {
        topicBadge
            .padding(.bottom, 4)
    }

    private func topActionButton(
        icon: String,
        title: String,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(
                            isPrimary
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.24, green: 0.80, blue: 0.99),
                                        Color(red: 0.47, green: 0.31, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color(red: 0.09, green: 0.16, blue: 0.27).opacity(0.80))
                        )
                        .frame(width: 44, height: 44)
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(isPrimary ? 0.0 : 0.12), lineWidth: 1)
                        }

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(title.uppercased())
                    .font(.custom("AvenirNext-DemiBold", size: 9))
                    .tracking(1.6)
                    .foregroundStyle(isPrimary ? Color(red: 0.19, green: 0.84, blue: 0.98) : Color.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func phraseTextBlock(in size: CGSize) -> some View {
        let textWidth = min(max(size.width - 96, 248), 620)
        let minHeight = size.height * (isTranslationVisible ? 0.19 : 0.23)
        let maxHeight = size.height * (isTranslationVisible ? 0.30 : 0.39)

        ScrollView(.vertical, showsIndicators: false) {
            HighlightedPhraseTextView(tokens: highlightedTokens) { token in
                Task {
                    let detail = await WordHighlightService.shared.detail(
                        for: token.normalizedWord,
                        phrase: phrase,
                        nativeLanguage: NativeLanguageLocalization.preferredNativeLanguage()
                    )
                    await MainActor.run {
                        selectedWordDetail = detail
                    }
                }
            }
            .id("manual-\(phrase.id.uuidString)")
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: minHeight, alignment: .center)
            .shadow(color: Color.black.opacity(0.60), radius: 16, x: 0, y: 8)
        }
        .id("manual-scroll-\(phrase.id.uuidString)")
        .frame(width: textWidth)
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .frame(maxWidth: size.width, alignment: .center)
    }

    private var translationText: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(phrase.translation)
                .font(.custom("AvenirNext-Regular", size: 18))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 4)
        }
        .frame(maxWidth: 560, maxHeight: 132)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var saveButton: some View {
        Button(action: onSave) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.11, green: 0.21, blue: 0.35).opacity(0.82))
                        .frame(width: 52, height: 52)
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        }

                    Image(systemName: localIsSaved ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text((localIsSaved ? LocalizedStrings.feedUnsaveButton : LocalizedStrings.feedSaveButton).uppercased())
                    .font(.custom("AvenirNext-DemiBold", size: 10))
                    .tracking(2.1)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PhraseCard(
        phrase: EnglishPhrase.mockPhrases[0],
        backgroundImageURL: nil,
        isSaved: false,
        isAudioPlaying: false,
        learningState: ReelLearningState(),
        highlightedTokens: [],
        currentUserID: nil,
        onPlayAudio: {},
        onSpeak: {},
        onTranslationOpened: {},
        onAskAI: {},
        onSave: {}
    )
}

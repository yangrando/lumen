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
    @State private var isDetailsSheetPresented = false
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
            let trailingMargin = max(28, geometry.safeAreaInsets.trailing + 28)
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

                        if phrase.hasStructuredDetails {
                            structuredDetailsSection
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
                        title: LocalizedStrings.feedSpeak,
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
        .sheet(isPresented: $isDetailsSheetPresented) {
            detailsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
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
        HStack(spacing: 8) {
            badgeLabel("\(phrase.category) • \(phrase.difficulty.rawValue)", accent: Color(red: 0.19, green: 0.84, blue: 0.98))
            if let subtopic = phrase.subtopic, !subtopic.isEmpty {
                badgeLabel(prettyLabel(subtopic), accent: .white.opacity(0.88))
            }
            if phrase.isFactLike {
                badgeLabel("FACT", accent: Color(red: 1.0, green: 0.87, blue: 0.45))
            } else if phrase.isDialogueLike {
                badgeLabel("DIALOGUE", accent: Color(red: 0.71, green: 0.84, blue: 1.0))
            }
        }
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
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
            }
            .frame(width: isPrimary ? 68 : 62)
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

    @ViewBuilder
    private var structuredDetailsSection: some View {
        Button {
            isDetailsSheetPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(LocalizedStrings.feedShowDetails)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 560, alignment: .leading)
    }

    private var detailsSheet: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 46, height: 5)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                Text(phrase.text)
                    .font(.custom("AvenirNext-Bold", size: 22))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if !phrase.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(phrase.translation)
                        .font(.custom("AvenirNext-Regular", size: 16))
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let context = phrase.context, !context.isEmpty {
                    infoBlock(title: LocalizedStrings.feedContext, body: context, accent: Color(red: 0.63, green: 0.85, blue: 1.0))
                }
                if let explanation = phrase.explanation, !explanation.isEmpty {
                    infoBlock(title: LocalizedStrings.feedExplanation, body: explanation, accent: Color(red: 0.70, green: 0.93, blue: 0.82))
                }
                if let didYouKnow = phrase.didYouKnow, !didYouKnow.isEmpty {
                    infoBlock(title: LocalizedStrings.feedDidYouKnow, body: didYouKnow, accent: Color(red: 1.0, green: 0.87, blue: 0.45))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Color(red: 0.06, green: 0.10, blue: 0.18))
    }

    private func infoBlock(title: String, body: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.custom("AvenirNext-DemiBold", size: 10))
                .tracking(1.6)
                .foregroundStyle(accent)
            Text(body)
                .font(.custom("AvenirNext-Regular", size: 15))
                .foregroundStyle(.white.opacity(0.93))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.13, blue: 0.22).opacity(0.72))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func badgeLabel(_ text: String, accent: Color) -> some View {
        Text(text)
            .font(.custom("AvenirNext-Bold", size: 12))
            .foregroundStyle(accent)
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

    private func prettyLabel(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
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

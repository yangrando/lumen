import SwiftUI
import UIKit
import Foundation

struct PhraseCard: View {
    let phrase: EnglishPhrase
    let backgroundImageURL: URL?
    let isSaved: Bool
    let isAudioPlaying: Bool
    @State private var isTranslationVisible = false
    @State private var localIsSaved = false
    @State private var isTextAutoScrolling = false
    @State private var textScrollSpeed: CGFloat = 28
    let onPlayAudio: () -> Void
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
                    VStack(spacing: 24) {
                        phraseTextBlock(in: geometry.size)

                        if isTranslationVisible {
                            translationText
                        }

                        if shouldShowReadingControls {
                            readingControls
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 28)
                }
            }
            .overlay(alignment: .topLeading) {
                topicBadge
                    .padding(.leading, horizontalMargin)
                    .padding(.top, topMargin)
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isTranslationVisible.toggle()
                            }
                        }
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
            isTextAutoScrolling = false
        }
        .onChange(of: isSaved) { _, newValue in
            localIsSaved = newValue
        }
    }

    private var shouldShowReadingControls: Bool {
        phrase.text.split { $0.isWhitespace || $0.isNewline }.count > 22
    }

    private var editorialStyle: EditorialStyle {
        let key = phrase.category.lowercased()
        if key.contains("business") || key.contains("econom") || key.contains("finance") {
            return .subtleGlass
        }
        return .glass
    }

    private var speedLabel: String {
        switch textScrollSpeed {
        case ..<26:
            return "0.8x"
        case 26..<34:
            return "1.0x"
        default:
            return "1.3x"
        }
    }

    private func cycleSpeed() {
        if textScrollSpeed < 26 {
            textScrollSpeed = 28
        } else if textScrollSpeed < 34 {
            textScrollSpeed = 36
        } else {
            textScrollSpeed = 22
        }
    }

    private var topicBadge: some View {
        Text("TOPIC:\n\(phrase.category.uppercased())")
            .font(.custom("AvenirNext-Bold", size: 9))
            .tracking(2.2)
            .foregroundStyle(Color(red: 0.19, green: 0.84, blue: 0.98))
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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

        if isTextAutoScrolling {
            AutoScrollTextView(
                text: phrase.text.uppercased(),
                font: UIFont(name: "AvenirNext-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold),
                textColor: .white,
                alignment: .center,
                isAutoScrolling: $isTextAutoScrolling,
                speedPointsPerSecond: textScrollSpeed
            )
            .frame(width: textWidth)
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .frame(maxWidth: .infinity, alignment: .center)
            .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                Text(phrase.text.uppercased())
                    .font(.custom("AvenirNext-Heavy", size: 20))
                    .tracking(-0.4)
                    .lineSpacing(2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: minHeight, alignment: .center)
                    .shadow(color: Color.black.opacity(0.60), radius: 16, x: 0, y: 8)
            }
            .frame(width: textWidth)
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .frame(maxWidth: size.width, alignment: .center)
        }
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

    private var readingControls: some View {
        HStack(spacing: 8) {
            Button {
                isTextAutoScrolling.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isTextAutoScrolling ? "pause.fill" : "play.fill")
                    Text(isTextAutoScrolling ? LocalizedStrings.feedReadingPause : LocalizedStrings.feedReadingPlay)
                }
                .font(.custom("AvenirNext-DemiBold", size: 12))
                .padding(.horizontal, 14)
                .frame(height: 40)
                .foregroundStyle(.white)
                .background(Color.white.opacity(0.10))
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                }
                .clipShape(Capsule())
            }

            Button {
                cycleSpeed()
            } label: {
                Text("\(LocalizedStrings.feedReadingSpeed) \(speedLabel)")
                    .font(.custom("AvenirNext-DemiBold", size: 12))
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(0.10))
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.28), lineWidth: 1)
                    }
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
        onPlayAudio: {},
        onAskAI: {},
        onSave: {}
    )
}

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
        ZStack {
            DynamicReelBackground(
                category: phrase.category,
                difficulty: phrase.difficulty,
                seed: phrase.id.uuidString + phrase.text
            )
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
                .ignoresSafeArea()
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.46),
                    Color.black.opacity(0.16),
                    Color.black.opacity(0.54)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.difficulty.rawValue)
                            .font(.custom("AvenirNext-DemiBold", size: 12))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        
                        Text(phrase.category)
                            .font(.custom("AvenirNext-Bold", size: 15))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                VStack(spacing: 18) {
                    VStack(spacing: 16) {
                        if isTextAutoScrolling {
                            AutoScrollTextView(
                                text: phrase.text,
                                font: UIFont(name: "AvenirNext-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold),
                                textColor: .white,
                                alignment: .center,
                                isAutoScrolling: $isTextAutoScrolling,
                                speedPointsPerSecond: textScrollSpeed
                            )
                            .frame(minHeight: mainTextMinHeight, maxHeight: mainTextMaxHeight)
                            .background(Color.clear)
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                Text(phrase.text)
                                    .font(.custom("AvenirNext-Bold", size: 20))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(minHeight: mainTextMinHeight, alignment: .center)
                            }
                            .frame(minHeight: mainTextMinHeight, maxHeight: mainTextMaxHeight)
                        }

                        if shouldShowReadingControls {
                            HStack(spacing: 10) {
                                Button {
                                    isTextAutoScrolling.toggle()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: isTextAutoScrolling ? "pause.fill" : "play.fill")
                                        Text(isTextAutoScrolling ? LocalizedStrings.feedReadingPause : LocalizedStrings.feedReadingPlay)
                                    }
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .padding(.horizontal, 12)
                                    .frame(height: 38)
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
                                        .padding(.horizontal, 12)
                                        .frame(height: 38)
                                        .foregroundStyle(.white)
                                        .background(Color.white.opacity(0.10))
                                        .overlay {
                                            Capsule()
                                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                                        }
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .padding(.bottom, isTranslationVisible ? translationOverlayHeight : 0)
                    .frame(maxWidth: .infinity)
                    .background(glassBackground)
                    .overlay(alignment: .bottom) {
                        if isTranslationVisible {
                            VStack(spacing: 12) {
                                Divider()
                                    .background(Color.white.opacity(0.25))

                                ScrollView(.vertical, showsIndicators: false) {
                                    Text(phrase.translation)
                                        .font(.custom("AvenirNext-Regular", size: 18))
                                        .foregroundStyle(.white.opacity(0.92))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(maxHeight: 150)
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 24)
                            .padding(.top, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.black.opacity(0.14),
                                        Color.black.opacity(0.22)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Bottom action buttons
                VStack(spacing: 12) {
                    // Play audio button
                    Button(action: onPlayAudio) {
                        HStack {
                            Image(systemName: isAudioPlaying ? "stop.fill" : "play.fill")
                            Text(isAudioPlaying ? LocalizedStrings.feedStopAudio : LocalizedStrings.feedListen)
                        }
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.10))
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                    }

                    // Toggle translation button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTranslationVisible.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text(LocalizedStrings.feedTranslate)
                        }
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.10))
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                    }
                    
                    // Ask AI button
                    Button(action: onAskAI) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(LocalizedStrings.feedAskAI)
                        }
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.10))
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
                .padding(.top, 20)
            }
        }
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

    private var translationOverlayHeight: CGFloat {
        190
    }

    private var mainTextMinHeight: CGFloat {
        isTranslationVisible ? 160 : 220
    }

    private var mainTextMaxHeight: CGFloat {
        isTranslationVisible ? 250 : 420
    }

    @ViewBuilder
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(editorialStyle == .glass ? 0.16 : 0.14))
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

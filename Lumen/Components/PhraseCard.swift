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
                    Color.black.opacity(0.38),
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with difficulty and category
                HStack {
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
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                HStack {
                    Spacer()
                    Button(action: {
                        localIsSaved.toggle()
                        onSave()
                    }) {
                        Image(systemName: localIsSaved ? "heart.fill" : "heart")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(localIsSaved ? .red : .white)
                            .padding(10)
                            .background(Color.black.opacity(0.16))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
                
                Spacer()
                
                // Main phrase text (centered)
                VStack(spacing: 16) {
                    AutoScrollTextView(
                        text: phrase.text,
                        font: UIFont(name: "AvenirNext-Bold", size: 29) ?? UIFont.systemFont(ofSize: 29, weight: .bold),
                        textColor: .white,
                        alignment: .center,
                        isAutoScrolling: $isTextAutoScrolling,
                        speedPointsPerSecond: textScrollSpeed
                    )
                    .frame(minHeight: 300, maxHeight: 540)
                    .background(Color.clear)

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
                                .padding(.horizontal, 10)
                                .frame(height: 32)
                                .foregroundStyle(.white)
                                .background(Color.white.opacity(0.14))
                                .clipShape(Capsule())
                            }

                            Button {
                                cycleSpeed()
                            } label: {
                                Text("\(LocalizedStrings.feedReadingSpeed) \(speedLabel)")
                                    .font(.custom("AvenirNext-DemiBold", size: 12))
                                    .padding(.horizontal, 10)
                                    .frame(height: 32)
                                    .foregroundStyle(.white)
                                    .background(Color.white.opacity(0.14))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Translation (toggle visibility)
                    if isTranslationVisible {
                        VStack(spacing: 12) {
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            ScrollView(.vertical, showsIndicators: false) {
                                Text(phrase.translation)
                                    .font(.custom("AvenirNext-Regular", size: 18))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(maxHeight: 150)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                
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
                        .frame(height: 44)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.2))
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
                        .frame(height: 44)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.2))
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
                        .frame(height: 44)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .padding(.top, 12)
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

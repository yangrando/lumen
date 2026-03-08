import SwiftUI

struct PhraseCard: View {
    let phrase: EnglishPhrase
    let isSaved: Bool
    let isAudioPlaying: Bool
    @State private var isTranslationVisible = false
    @State private var localIsSaved = false
    let onPlayAudio: () -> Void
    let onAskAI: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        ZStack {
            // Full screen background with gradient
            LinearGradient.primaryGradientDiagonal
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with difficulty and category
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.difficulty.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        
                        Text(phrase.category)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                .padding(16)

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
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Main phrase text (centered)
                VStack(spacing: 16) {
                    Text(phrase.text)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(6)
                    
                    // Translation (toggle visibility)
                    if isTranslationVisible {
                        VStack(spacing: 12) {
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            Text(phrase.translation)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(5)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Bottom action buttons
                VStack(spacing: 12) {
                    // Play audio button
                    Button(action: onPlayAudio) {
                        HStack {
                            Image(systemName: isAudioPlaying ? "stop.fill" : "play.fill")
                            Text(isAudioPlaying ? LocalizedStrings.feedStopAudio : LocalizedStrings.feedListen)
                        }
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
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            localIsSaved = isSaved
        }
        .onChange(of: isSaved) { _, newValue in
            localIsSaved = newValue
        }
    }
}

#Preview {
    PhraseCard(
        phrase: EnglishPhrase.mockPhrases[0],
        isSaved: false,
        isAudioPlaying: false,
        onPlayAudio: {},
        onAskAI: {},
        onSave: {}
    )
}

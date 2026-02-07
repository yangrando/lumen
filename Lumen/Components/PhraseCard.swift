import SwiftUI

struct PhraseCard: View {
    let phrase: EnglishPhrase
    let isSaved: Bool
    @State private var isTranslationVisible = false
    @State private var localIsSaved = false
    let onAskAI: () -> Void
    let onSave: (Bool) -> Void
    
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
                    
                    // Save button
                    Button(action: {
                        localIsSaved.toggle()
                        onSave(localIsSaved)
                    }) {
                        Image(systemName: localIsSaved ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundStyle(localIsSaved ? .red : .white)
                    }
                }
                .padding(16)
                
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
    }
}

#Preview {
    PhraseCard(
        phrase: EnglishPhrase.mockPhrases[0],
        isSaved: false,
        onAskAI: {},
        onSave: { _ in }
    )
}

import SwiftUI

struct FeedView: View {
    @State private var phrases = EnglishPhrase.mockPhrases
    @State private var savedPhraseIDs: Set<UUID> = []
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            // Background
            LumenColors.navyDark
                .ignoresSafeArea()
            
            // TabView for vertical scroll effect (fullscreen)
            if !phrases.isEmpty {
                VStack(spacing: 0) {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<phrases.count, id: \.self) { index in
                            PhraseCard(
                                phrase: phrases[index],
                                isSaved: savedPhraseIDs.contains(phrases[index].id),
                                onAskAI: {
                                    // TODO: Implement AI feedback
                                    print("Ask AI about: \(phrases[index].text)")
                                },
                                onSave: { isSaved in
                                    if isSaved {
                                        savedPhraseIDs.insert(phrases[index].id)
                                    } else {
                                        savedPhraseIDs.remove(phrases[index].id)
                                    }
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundStyle(LumenColors.textSecondary)
                    
                    Text(LocalizedStrings.feedEmptyTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(LocalizedStrings.feedEmptyDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        FeedView()
    }
}

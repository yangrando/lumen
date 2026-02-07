//
//  SavedPhrasesView.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 04/01/26.
//

import SwiftUI

struct SavedPhrasesView: View {
    @Binding var savedPhraseIDs: Set<UUID>
    let allPhrases: [EnglishPhrase]
    @Environment(\.dismiss) var dismiss
    
    var savedPhrases: [EnglishPhrase] {
        allPhrases.filter { savedPhraseIDs.contains($0.id) }
    }
    
    var body: some View {
        ZStack {
            // Background
            LumenColors.navyDark
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(LinearGradient.primaryGradient)
                    }
                    
                    Spacer()
                    
                    Text(LocalizedStrings.feedSavedPhrases)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Placeholder for future actions
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.clear)
                }
                .padding(16)
                
                // List of saved phrases
                if !savedPhrases.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(savedPhrases) { phrase in
                                SavedPhraseRow(phrase: phrase)
                            }
                        }
                        .padding(16)
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(LumenColors.textSecondary)
                        
                        Text("No saved phrases yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text("Start saving phrases to see them here")
                            .font(.system(size: 14))
                            .foregroundStyle(LumenColors.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Saved Phrase Row Component
struct SavedPhraseRow: View {
    let phrase: EnglishPhrase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phrase.text)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(phrase.translation)
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                }
                
                Spacer()
                
                Text(phrase.difficulty.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(LumenColors.navyLight)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        SavedPhrasesView(
            savedPhraseIDs: .constant(Set([EnglishPhrase.mockPhrases[0].id])),
            allPhrases: EnglishPhrase.mockPhrases
        )
    }
}

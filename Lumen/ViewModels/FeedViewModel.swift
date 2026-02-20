import Foundation
import SwiftUI
import Combine

// MARK: - Feed ViewModel

@MainActor
class FeedViewModel: ObservableObject {
    @Published var phrases: [EnglishPhrase] = []
    @Published var savedPhraseIDs: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let aiService = AIService.shared
    
    // User preferences (these would come from onboarding)
    private var userLevel: String = "Intermediate"
    private var userInterests: [String] = ["Technology", "Business"]
    private var userObjectives: [String] = ["Improve Speaking", "Expand Vocabulary"]
    
    init() {
        Task {
            await loadPhrases()
        }
    }
    
    
    func loadPhrases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            phrases = try await aiService.generatePhrases(
                level: userLevel,
                interests: userInterests,
                objectives: userObjectives,
                count: 10
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            // Fallback to mock phrases if API fails
            phrases = EnglishPhrase.mockPhrases
        }
    }
    
    // MARK: - Save/Unsave Phrase
    
    func toggleSavePhrase(_ phraseID: UUID) {
        if savedPhraseIDs.contains(phraseID) {
            savedPhraseIDs.remove(phraseID)
        } else {
            savedPhraseIDs.insert(phraseID)
        }
        
        // TODO: Persist saved phrases to local database
    }
    
    // MARK: - Get AI Feedback
    
    func getPhraseFeedback(_ phrase: String) async -> String {
        do {
            let feedback = try await aiService.getPhraseFeedback(
                phrase: phrase,
                userLevel: userLevel
            )
            return feedback
        } catch {
            return "Unable to get feedback at this moment. Please try again later."
        }
    }
    
    // MARK: - Translate Phrase
    
    func translatePhrase(_ phrase: String) async -> String {
        do {
            let translation = try await aiService.translatePhrase(phrase)
            return translation
        } catch {
            return "Translation unavailable"
        }
    }
    
    // MARK: - Update User Preferences
    
    func updateUserPreferences(
        level: String,
        interests: [String],
        objectives: [String]
    ) {
        self.userLevel = level
        self.userInterests = interests
        self.userObjectives = objectives
        
        Task {
            await loadPhrases()
        }
    }
}

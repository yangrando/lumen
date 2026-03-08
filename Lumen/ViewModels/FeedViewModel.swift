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
    private let authService = AuthService.shared
    
    // User preferences (these would come from onboarding)
    private var userLevel: String = "Intermediate"
    private var userNativeLanguage: String = "Portuguese (Brazil)"
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
            if let token = SessionService.shared.accessToken {
                let preferences = try await authService.fetchCurrentUserPreferences(accessToken: token)
                userLevel = preferences.level
                userNativeLanguage = preferences.nativeLanguage
                if !preferences.interests.isEmpty {
                    userInterests = preferences.interests
                }
                if !preferences.objectives.isEmpty {
                    userObjectives = preferences.objectives
                }
            }

            phrases = try await aiService.generatePhrases(
                level: userLevel,
                nativeLanguage: userNativeLanguage,
                interests: userInterests,
                objectives: userObjectives,
                count: 10
            )

            // Keep feed scroll usable even when model under-produces.
            var refillAttempts = 0
            while phrases.count < 3 && refillAttempts < 3 {
                refillAttempts += 1
                let extra = try await aiService.generatePhrases(
                    level: userLevel,
                    nativeLanguage: userNativeLanguage,
                    interests: userInterests,
                    objectives: userObjectives,
                    count: 10
                )
                phrases.append(contentsOf: extra)
            }
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
            let translation = try await aiService.translatePhrase(
                phrase,
                targetLanguage: userNativeLanguage
            )
            return translation
        } catch {
            return "Translation unavailable"
        }
    }
    
    // MARK: - Update User Preferences
    
    func updateUserPreferences(
        level: String,
        nativeLanguage: String,
        interests: [String],
        objectives: [String]
    ) {
        self.userLevel = level
        self.userNativeLanguage = nativeLanguage
        self.userInterests = interests
        self.userObjectives = objectives
        
        Task {
            await loadPhrases()
        }
    }
}

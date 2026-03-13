import Foundation
import SwiftUI
import Combine

// MARK: - Feed ViewModel

@MainActor
class FeedViewModel: ObservableObject {
    private struct ContentPolicy {
        let minChars: Int
        let maxChars: Int
        let minWords: Int
        let maxWords: Int
        let preferredSentenceRange: String
    }

    private enum PaginationError: LocalizedError {
        case noNewPhrases

        var errorDescription: String? {
            switch self {
            case .noNewPhrases:
                return LocalizedStrings.feedErrorDescription
            }
        }
    }

    enum TailState: Equatable {
        case idle
        case loading
        case reconnecting(remainingSeconds: Int)
        case failed(message: String)
    }

    @Published var phrases: [EnglishPhrase] = []
    @Published var backgroundURLs: [UUID: URL] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var tailState: TailState = .idle
    
    private let aiService = AIService.shared
    private let backgroundService = ReelBackgroundService.shared
    private let authService = AuthService.shared
    
    // User preferences (these would come from onboarding)
    private var userLevel: String = "Intermediate"
    private var userNativeLanguage: String = "Portuguese (Brazil)"
    private var userInterests: [String] = ["Technology", "Business"]
    private var userObjectives: [String] = ["Improve Speaking", "Expand Vocabulary"]
    private var favoriteCategories: [String] = []
    private var isFetchingMore = false
    private var backgroundTasks: Set<UUID> = []
    private let pageSize = 8
    private let prefetchThreshold = 2
    
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

            phrases = try await generateBatch(excludedTexts: [])

            phrases = deduplicate(phrases).filter { isWithinTargetLength($0.text) }
            if phrases.count < 3 {
                try await fetchMorePhrases(force: true)
            }
            prefetchBackgrounds(around: 0)
            tailState = .idle
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            // Fallback to mock phrases if API fails
            phrases = EnglishPhrase.mockPhrases
        }
    }

    func prefetchBackgrounds(around index: Int) {
        guard !phrases.isEmpty else { return }
        let start = max(0, index - 1)
        let end = min(phrases.count - 1, index + 2)
        guard start <= end else { return }
        for i in start...end {
            ensureBackground(for: phrases[i])
        }
    }

    private func ensureBackground(for phrase: EnglishPhrase) {
        guard backgroundURLs[phrase.id] == nil else { return }
        guard !backgroundTasks.contains(phrase.id) else { return }
        backgroundTasks.insert(phrase.id)

        Task {
            defer { backgroundTasks.remove(phrase.id) }
            do {
                let url = try await backgroundService.urlForPhrase(
                    text: phrase.text,
                    category: phrase.category,
                    difficulty: phrase.difficulty.rawValue,
                    seed: phrase.id.uuidString
                )
                backgroundURLs[phrase.id] = url
            } catch {
                // Keep local dynamic background as fallback when remote generation fails.
            }
        }
    }

    func ensureMorePhrasesIfNeeded(currentIndex: Int) {
        guard !phrases.isEmpty else { return }
        let reachedTailPage = currentIndex >= phrases.count
        let nearEndOfContent = currentIndex >= phrases.count - prefetchThreshold
        guard reachedTailPage || nearEndOfContent else { return }
        guard !isFetchingMore else { return }

        Task {
            do {
                try await fetchMorePhrases(force: reachedTailPage)
            } catch {
                await retryFetchMoreAfterConnectionDrop()
            }
        }
    }

    func retryLoadMore() {
        Task {
            do {
                try await fetchMorePhrases(force: true)
            } catch {
                await retryFetchMoreAfterConnectionDrop()
            }
        }
    }
    
    func updateFavoriteSignals(from favorites: [FavoritePhrase]) {
        favoriteCategories = Array(
            Set(
                favorites
                    .map(\.category)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        ).sorted()
    }

    private func fetchMorePhrases(force: Bool = false) async throws {
        guard !isFetchingMore else { return }
        if !force && phrases.isEmpty { return }

        isFetchingMore = true
        tailState = .loading
        defer {
            isFetchingMore = false
        }

        let excluded = phrases.map(\.text)
        let newBatch = try await generateBatch(excludedTexts: excluded)

        let uniqueNew = deduplicate(newBatch).filter { candidate in
            isWithinTargetLength(candidate.text) &&
            !phrases.contains { normalize($0.text) == normalize(candidate.text) }
        }

        if uniqueNew.isEmpty {
            let secondBatch = try await generateBatch(excludedTexts: excluded)
            let secondUnique = deduplicate(secondBatch).filter { candidate in
                isWithinTargetLength(candidate.text) &&
                !phrases.contains { normalize($0.text) == normalize(candidate.text) }
            }
            guard !secondUnique.isEmpty else {
                throw PaginationError.noNewPhrases
            }
            phrases.append(contentsOf: secondUnique)
        } else {
            phrases.append(contentsOf: uniqueNew)
        }
        tailState = .idle
    }

    private func retryFetchMoreAfterConnectionDrop() async {
        let totalWindow = 30
        var elapsed = 0
        while elapsed < totalWindow {
            let remaining = max(0, totalWindow - elapsed)
            tailState = .reconnecting(remainingSeconds: remaining)
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                elapsed += 2
                try await fetchMorePhrases(force: true)
                tailState = .idle
                return
            } catch {
                continue
            }
        }
        tailState = .failed(message: LocalizedStrings.feedErrorDescription)
    }

    private func deduplicate(_ items: [EnglishPhrase]) -> [EnglishPhrase] {
        var seen = Set<String>()
        var unique: [EnglishPhrase] = []
        for item in items {
            let key = normalize(item.text)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(item)
        }
        return unique
    }

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private var contentPolicy: ContentPolicy {
        let normalized = userLevel
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: " ", with: "-")

        // CEFR-like mapping, ready for future expansion to other languages.
        if normalized.contains("a1") ||
            normalized.contains("a2") ||
            normalized.contains("beginner") ||
            normalized.contains("elementary") {
            return ContentPolicy(
                minChars: 35,
                maxChars: 260,
                minWords: 6,
                maxWords: 45,
                preferredSentenceRange: "1 to 3 short sentences"
            )
        }

        if normalized.contains("c1") ||
            normalized.contains("c2") ||
            normalized.contains("advanced") {
            return ContentPolicy(
                minChars: 220,
                maxChars: 900,
                minWords: 32,
                maxWords: 150,
                preferredSentenceRange: "3 to 6 well-connected sentences"
            )
        }

        // Default to intermediate family (B1/B2 + intermediate labels).
        return ContentPolicy(
            minChars: 120,
            maxChars: 560,
            minWords: 18,
            maxWords: 90,
            preferredSentenceRange: "2 to 4 sentences"
        )
    }

    private func isWithinTargetLength(_ text: String) -> Bool {
        let charCount = text.trimmingCharacters(in: .whitespacesAndNewlines).count
        let wordCount = text
            .split { $0.isWhitespace || $0.isNewline }
            .count
        let policy = contentPolicy
        return charCount >= policy.minChars &&
            charCount <= policy.maxChars &&
            wordCount >= policy.minWords &&
            wordCount <= policy.maxWords
    }

    private func generateBatch(excludedTexts: [String]) async throws -> [EnglishPhrase] {
        let effectiveInterests = Array(Set(userInterests + favoriteCategories)).sorted()
        let policy = contentPolicy
        return try await aiService.generatePhrases(
            level: userLevel,
            nativeLanguage: userNativeLanguage,
            interests: effectiveInterests,
            objectives: userObjectives,
            count: pageSize,
            excludedTexts: excludedTexts,
            minWordsPerCard: policy.minWords,
            maxWordsPerCard: policy.maxWords,
            minCharactersPerCard: policy.minChars,
            maxCharactersPerCard: policy.maxChars,
            preferredSentenceRange: policy.preferredSentenceRange
        )
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
            return LocalizedStrings.feedbackUnavailable
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
            return LocalizedStrings.translationUnavailable
        }
    }

    // MARK: - Ask AI

    func askAI(phrase: String, question: String) async -> String {
        do {
            return try await aiService.askAboutPhrase(
                phrase: phrase,
                question: question,
                userLevel: userLevel,
                nativeLanguage: userNativeLanguage
            )
        } catch {
            return LocalizedStrings.feedbackUnavailable
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

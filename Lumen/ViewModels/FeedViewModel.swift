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

    enum BackgroundState: Equatable {
        case loading
        case ready(URL?)
    }

    @Published var phrases: [EnglishPhrase] = []
    @Published var backgroundURLs: [UUID: URL] = [:]
    @Published var backgroundStates: [UUID: BackgroundState] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var tailState: TailState = .idle
    
    private let aiService = AIService.shared
    private let backgroundService = ReelBackgroundService.shared
    private let authService = AuthService.shared
    private let usesRemoteBackgrounds = false
    
    // User preferences (these would come from onboarding)
    private var userLevel: String = "B1"
    private var userNativeLanguage: String = "Portuguese (Brazil)"
    private var userInterests: [String] = ["Technology", "Business"]
    private var userObjectives: [String] = ["Improve Speaking", "Expand Vocabulary"]
    private var favoriteCategories: [String] = []
    private var isFetchingMore = false
    private var loadMoreTask: Task<Void, Never>?
    private var backgroundTasks: Set<UUID> = []
    private let pageSize = 8
    private let initialPageSize = 5
    
    init() {
        Task {
            await loadPhrases()
        }
    }
    
    
    func loadPhrases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentUserID = SessionService.shared.currentUser?.sub
            if let token = SessionService.shared.accessToken {
                if let cachedPreferences = authService.cachedPreferences(for: currentUserID) {
                    apply(preferences: cachedPreferences)
                    Task {
                        await refreshPreferencesInBackground(accessToken: token)
                    }
                } else {
                    let preferences = try await authService.fetchCurrentUserPreferences(accessToken: token)
                    apply(preferences: preferences)
                }
            }

            phrases = try await generateBatch(excludedTexts: [], count: initialPageSize)

            phrases = deduplicate(phrases).filter { isWithinTargetLength($0.text) }
            tailState = .idle
            isLoading = false
            if phrases.count < 3 {
                Task {
                    try? await fetchMorePhrases(force: true)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            
            // Fallback to mock phrases if API fails
            phrases = EnglishPhrase.mockPhrases
        }
    }

    func prefetchBackgrounds(around index: Int) {
        guard usesRemoteBackgrounds else { return }
        guard !phrases.isEmpty else { return }
        let start = max(0, index - 1)
        let end = min(phrases.count - 1, index + 2)
        guard start <= end else { return }
        for i in start...end {
            ensureBackground(for: phrases[i])
        }
    }

    func isBackgroundReady(for phraseID: UUID) -> Bool {
        guard usesRemoteBackgrounds else { return true }
        if let state = backgroundStates[phraseID] {
            if case .ready = state { return true }
            return false
        }
        return false
    }

    private func ensureBackground(for phrase: EnglishPhrase) {
        guard usesRemoteBackgrounds else {
            backgroundStates[phrase.id] = .ready(nil)
            return
        }
        if let state = backgroundStates[phrase.id], case .ready = state {
            return
        }
        guard !backgroundTasks.contains(phrase.id) else { return }
        backgroundStates[phrase.id] = .loading
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
                backgroundStates[phrase.id] = .ready(url)
            } catch {
                // Keep local dynamic background as fallback when remote generation fails.
                backgroundStates[phrase.id] = .ready(nil)
            }
        }
    }

    private func primeInitialBackgrounds() async {
        guard usesRemoteBackgrounds else { return }
        guard !phrases.isEmpty else { return }
        let primeItems = Array(phrases.prefix(3))
        await withTaskGroup(of: Void.self) { group in
            for phrase in primeItems {
                group.addTask { [weak self] in
                    await self?.ensureBackgroundImmediately(for: phrase)
                }
            }
        }
        prefetchBackgrounds(around: 0)
    }

    private func ensureBackgroundImmediately(for phrase: EnglishPhrase) async {
        guard usesRemoteBackgrounds else {
            backgroundStates[phrase.id] = .ready(nil)
            return
        }
        if let state = backgroundStates[phrase.id], case .ready = state {
            return
        }
        backgroundStates[phrase.id] = .loading
        do {
            let url = try await backgroundService.urlForPhrase(
                text: phrase.text,
                category: phrase.category,
                difficulty: phrase.difficulty.rawValue,
                seed: phrase.id.uuidString
            )
            backgroundURLs[phrase.id] = url
            backgroundStates[phrase.id] = .ready(url)
        } catch {
            backgroundStates[phrase.id] = .ready(nil)
        }
    }

    func ensureMorePhrasesIfNeeded(currentIndex: Int) {
        guard !phrases.isEmpty else { return }
        let reachedTailPage = currentIndex >= phrases.count
        guard reachedTailPage else { return }
        guard !isFetchingMore else { return }
        guard loadMoreTask == nil else { return }

        loadMoreTask = Task { [weak self] in
            guard let self else { return }
            defer { self.loadMoreTask = nil }
            do {
                try await self.fetchMorePhrases(force: true)
            } catch {
                await self.retryFetchMoreAfterConnectionDrop()
            }
        }
    }

    func retryLoadMore() {
        guard loadMoreTask == nil else { return }
        loadMoreTask = Task { [weak self] in
            guard let self else { return }
            defer { self.loadMoreTask = nil }
            do {
                try await self.fetchMorePhrases(force: true)
            } catch {
                await self.retryFetchMoreAfterConnectionDrop()
            }
        }
    }

    func cancelLoadMore() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
        isFetchingMore = false
        if case .loading = tailState {
            tailState = .idle
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
            if Task.isCancelled {
                tailState = .idle
                return
            }
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

        if normalized.contains("a1") {
            return ContentPolicy(
                minChars: 28,
                maxChars: 140,
                minWords: 4,
                maxWords: 18,
                preferredSentenceRange: "1 or 2 very short sentences"
            )
        }

        if normalized.contains("a2") {
            return ContentPolicy(
                minChars: 55,
                maxChars: 220,
                minWords: 8,
                maxWords: 30,
                preferredSentenceRange: "1 to 3 short connected sentences"
            )
        }

        if normalized.contains("b2") {
            return ContentPolicy(
                minChars: 170,
                maxChars: 520,
                minWords: 24,
                maxWords: 82,
                preferredSentenceRange: "2 to 4 well-connected sentences"
            )
        }

        if normalized.contains("c1") {
            return ContentPolicy(
                minChars: 220,
                maxChars: 720,
                minWords: 32,
                maxWords: 115,
                preferredSentenceRange: "3 to 5 developed sentences"
            )
        }

        if normalized.contains("c2") {
            return ContentPolicy(
                minChars: 260,
                maxChars: 860,
                minWords: 38,
                maxWords: 135,
                preferredSentenceRange: "3 to 6 nuanced sentences"
            )
        }

        return ContentPolicy(
            minChars: 110,
            maxChars: 360,
            minWords: 16,
            maxWords: 56,
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

    private func generateBatch(excludedTexts: [String], count: Int? = nil) async throws -> [EnglishPhrase] {
        let effectiveInterests = Array(Set(userInterests + favoriteCategories)).sorted()
        let policy = contentPolicy
        return try await aiService.generatePhrases(
            level: userLevel,
            nativeLanguage: userNativeLanguage,
            interests: effectiveInterests,
            objectives: userObjectives,
            count: count ?? pageSize,
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

    private func apply(preferences: UserPreferences) {
        userLevel = preferences.level
        userNativeLanguage = preferences.nativeLanguage
        if !preferences.interests.isEmpty {
            userInterests = preferences.interests
        }
        if !preferences.objectives.isEmpty {
            userObjectives = preferences.objectives
        }
    }

    private func refreshPreferencesInBackground(accessToken: String) async {
        do {
            let preferences = try await authService.fetchCurrentUserPreferences(accessToken: accessToken)
            apply(preferences: preferences)
        } catch {
            // Keep the feed responsive; remote refresh is best-effort here.
        }
    }
}

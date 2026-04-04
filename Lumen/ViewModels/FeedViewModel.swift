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
    @Published var bufferedPhraseCount = 0
    @Published var isBackgroundFetching = false
    
    private let aiService = AIService.shared
    private let backgroundService = ReelBackgroundService.shared
    private let authService = AuthService.shared
    private let logger = Logger.shared
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
    private var queuedPhrases: [EnglishPhrase] = []
    private var seenPhraseKeys = Set<String>()
    private var currentVisibleIndex = 0
    private var lastAutomaticFetchAt: Date?
    private var lastFetchAddedCount = 0
    private var activeFetchRequestID: String?
    private var fetchCooldownUntil: Date?
    private var furthestConsumedIndex = 0
    private var firstBlockingLoadingLogged = false
    private let preloadThreshold = 22
    private let lowWatermark = 22
    private let visibleBufferFloor = 28
    private let refillSize = 32
    private let targetBufferSize = 64
    private let minimumBlockingRecoveryBuffer = 28
    private let minimumAutomaticFetchSpacing: TimeInterval = 2
    private let lowYieldFetchCooldown: TimeInterval = 12
    private let initialPageSize = 40
    
    init() {
        Task {
            await loadPhrases()
        }
    }
    
    
    func loadPhrases() async {
        isLoading = true
        errorMessage = nil
        resetFeedState()
        
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

            let initialBatch = try await generateBatch(excludedTexts: [], count: initialPageSize)
            _ = ingestIncoming(initialBatch.phrases, source: "initial_load")
            _ = promoteBufferedPhrasesIfNeeded(trigger: "initial_load", desiredVisibleRemaining: visibleBufferFloor)
            currentVisibleIndex = 0
            tailState = .idle
            isLoading = false
            logger.info(
                "Feed initial load completed - requested: \(initialPageSize), visibleLoaded: \(phrases.count), queued: \(queuedPhrases.count), bufferTarget: \(targetBufferSize)"
            )
            if totalAvailableReels(after: currentVisibleIndex) < targetBufferSize {
                logger.info(
                    "Feed initial top-up triggered - visibleLoaded: \(phrases.count), queued: \(queuedPhrases.count), totalAvailable: \(totalAvailableReels(after: currentVisibleIndex)), targetBuffer: \(targetBufferSize)"
                )
                loadMoreTask = Task { [weak self] in
                    guard let self else { return }
                    defer { self.loadMoreTask = nil }
                    do {
                        try await self.fetchMorePhrases(force: true, trigger: "initial_top_up")
                    } catch {
                        await self.handleLoadMoreFailure(error)
                    }
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
        guard !phrases.isEmpty || !queuedPhrases.isEmpty else { return }
        currentVisibleIndex = max(0, min(currentIndex, max(phrases.count, 0)))
        furthestConsumedIndex = max(furthestConsumedIndex, min(currentVisibleIndex, max(phrases.count - 1, 0)))
        let promoted = promoteBufferedPhrasesIfNeeded(trigger: "scroll", desiredVisibleRemaining: visibleBufferFloor)
        let remaining = remainingReels(after: currentVisibleIndex)
        let totalAvailable = totalAvailableReels(after: currentVisibleIndex)
        let reachedTailPage = currentIndex >= phrases.count
        if promoted > 0 {
            logger.info(
                "Feed buffer promoted queued reels - trigger: scroll, visibleIndex: \(currentVisibleIndex), promoted: \(promoted), visibleTotal: \(phrases.count), queuedRemaining: \(queuedPhrases.count)"
            )
        }
        if reachedTailPage && isFetchingMore {
            if case .reconnecting = tailState {
                return
            }
            if case .failed = tailState {
                return
            }
            tailState = .loading
            return
        }
        let shouldPreload = totalAvailable <= lowWatermark || (remaining <= preloadThreshold && queuedPhrases.count <= 1)
        guard reachedTailPage || shouldPreload else { return }
        guard !isFetchingMore else { return }
        guard loadMoreTask == nil else { return }
        guard canStartAutomaticFetch(triggeredByTail: reachedTailPage) else {
            logger.info(
                "Feed preload skipped - visibleIndex: \(currentVisibleIndex), visibleTotal: \(phrases.count), queued: \(queuedPhrases.count), remainingVisible: \(remaining), totalAvailable: \(totalAvailable), lastAdded: \(lastFetchAddedCount)"
            )
            return
        }

        let trigger = reachedTailPage ? "tail_exhausted" : "preload_threshold"
        let requestedCount = recommendedFetchCount(currentIndex: currentVisibleIndex)
        logger.info(
            "Feed preload triggered - trigger: \(trigger), visibleIndex: \(currentVisibleIndex), visibleTotal: \(phrases.count), queued: \(queuedPhrases.count), remainingVisible: \(remaining), totalAvailable: \(totalAvailable), requested: \(requestedCount), preloadLead: \(totalAvailable)"
        )

        loadMoreTask = Task { [weak self] in
            guard let self else { return }
            defer { self.loadMoreTask = nil }
            do {
                try await self.fetchMorePhrases(force: true, trigger: trigger)
            } catch {
                await self.handleLoadMoreFailure(error)
            }
        }
    }

    func retryLoadMore() {
        guard loadMoreTask == nil else { return }
        loadMoreTask = Task { [weak self] in
            guard let self else { return }
            defer { self.loadMoreTask = nil }
            do {
                try await self.fetchMorePhrases(force: true, trigger: "manual_retry")
            } catch {
                await self.handleLoadMoreFailure(error)
            }
        }
    }

    func cancelLoadMore() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
        isFetchingMore = false
        isBackgroundFetching = false
        if case .loading = tailState {
            tailState = .idle
        }
    }

    var shouldShowBlockingTail: Bool {
        guard !isLoading else { return false }
        let exhausted = totalAvailableReels(after: currentVisibleIndex) == 0
        switch tailState {
        case .loading, .reconnecting, .failed:
            return exhausted
        case .idle:
            return exhausted
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

    private func fetchMorePhrases(force: Bool = false, trigger: String = "unspecified") async throws {
        guard !isFetchingMore else { return }
        if !force && phrases.isEmpty && queuedPhrases.isEmpty { return }

        let bufferBefore = totalAvailableReels(after: currentVisibleIndex)
        let requestedCount = recommendedFetchCount(currentIndex: currentVisibleIndex)
        let requestID = UUID().uuidString
        activeFetchRequestID = requestID
        isFetchingMore = true
        let isBlockingFetch = totalAvailableReels(after: currentVisibleIndex) == 0
        isBackgroundFetching = !isBlockingFetch
        if isBlockingFetch {
            tailState = .loading
            if !firstBlockingLoadingLogged {
                firstBlockingLoadingLogged = true
                logger.warning(
                    "Feed first blocking loading - consumedReels: \(furthestConsumedIndex + 1), visibleIndex: \(currentVisibleIndex), visibleCount: \(phrases.count), queuedCount: \(queuedPhrases.count), trigger: \(trigger)"
                )
            }
        }
        if trigger != "manual_retry" {
            lastAutomaticFetchAt = Date()
        }
        logger.info(
            "Feed buffer fetch starting - trigger: \(trigger), requestID: \(requestID), visibleIndex: \(currentVisibleIndex), visibleBefore: \(phrases.count), queuedBefore: \(queuedPhrases.count), bufferBefore: \(bufferBefore), requested: \(requestedCount), blocking: \(isBlockingFetch)"
        )
        defer {
            isFetchingMore = false
            isBackgroundFetching = false
        }

        var returnedCount = 0
        var appended = 0
        var promoted = 0
        var bufferAfter = bufferBefore

        let excluded = allKnownTexts()
        let newBatch = try await generateBatch(excludedTexts: excluded, count: requestedCount, requestID: requestID)
        guard activeFetchRequestID == requestID else {
            logger.warning("Feed buffer fetch ignored stale response - requestID: \(requestID), activeRequestID: \(activeFetchRequestID ?? "-")")
            return
        }

        returnedCount += newBatch.metadata?.returnedCount ?? newBatch.phrases.count
        appended += ingestIncoming(newBatch.phrases, source: trigger)
        promoted += promoteBufferedPhrasesIfNeeded(trigger: trigger, desiredVisibleRemaining: visibleBufferFloor)
        bufferAfter = totalAvailableReels(after: currentVisibleIndex)

        if isBlockingFetch && bufferAfter < minimumBlockingRecoveryBuffer {
            let recoveryCount = max(refillSize, minimumBlockingRecoveryBuffer - bufferAfter + lowWatermark)
            logger.info(
                "Feed blocking recovery top-up starting - trigger: \(trigger), requestID: \(requestID), bufferAfter: \(bufferAfter), recoveryTarget: \(minimumBlockingRecoveryBuffer), requested: \(recoveryCount)"
            )

            let recoveryBatch = try await generateBatch(
                excludedTexts: allKnownTexts(),
                count: recoveryCount,
                requestID: requestID
            )
            guard activeFetchRequestID == requestID else {
                logger.warning("Feed blocking recovery ignored stale response - requestID: \(requestID), activeRequestID: \(activeFetchRequestID ?? "-")")
                return
            }

            returnedCount += recoveryBatch.metadata?.returnedCount ?? recoveryBatch.phrases.count
            appended += ingestIncoming(recoveryBatch.phrases, source: "\(trigger)_blocking_recovery")
            promoted += promoteBufferedPhrasesIfNeeded(trigger: "\(trigger)_blocking_recovery", desiredVisibleRemaining: visibleBufferFloor)
            bufferAfter = totalAvailableReels(after: currentVisibleIndex)
            logger.info(
                "Feed blocking recovery top-up completed - trigger: \(trigger), requestID: \(requestID), bufferAfter: \(bufferAfter), returnedTotal: \(returnedCount), appendedTotal: \(appended), promotedTotal: \(promoted)"
            )
        }

        if appended == 0 {
            lastFetchAddedCount = 0
            logger.warning(
                "Feed buffer fetch yielded no acceptable phrases - trigger: \(trigger), requestID: \(requestID), requested: \(requestedCount), returned: \(returnedCount), visibleAfter: \(phrases.count), queuedAfter: \(queuedPhrases.count)"
            )
            if totalAvailableReels(after: currentVisibleIndex) == 0 {
                throw PaginationError.noNewPhrases
            }
            tailState = .idle
            return
        }
        lastFetchAddedCount = appended
        fetchCooldownUntil = nil
        logger.info(
            "Feed buffer fetch completed - trigger: \(trigger), requestID: \(requestID), visibleAfter: \(phrases.count), queuedAfter: \(queuedPhrases.count), bufferAfter: \(bufferAfter), returned: \(returnedCount), appended: \(appended), promoted: \(promoted)"
        )
        if activeFetchRequestID == requestID {
            activeFetchRequestID = nil
        }
        tailState = .idle

        let shouldContinueTopUp =
            trigger != "manual_retry" &&
            (
                bufferAfter < targetBufferSize ||
                appended < max(lowWatermark, requestedCount / 2)
            )

        if shouldContinueTopUp && loadMoreTask == nil {
            logger.info(
                "Feed chained top-up scheduled - previousTrigger: \(trigger), requestID: \(requestID), bufferAfter: \(bufferAfter), targetBuffer: \(targetBufferSize), requested: \(requestedCount), returned: \(returnedCount), appended: \(appended)"
            )
            loadMoreTask = Task { [weak self] in
                guard let self else { return }
                defer { self.loadMoreTask = nil }
                do {
                    try await Task.sleep(nanoseconds: 350_000_000)
                    try await self.fetchMorePhrases(force: true, trigger: "chained_top_up")
                } catch {
                    await self.handleLoadMoreFailure(error)
                }
            }
        }
    }

    private func handleLoadMoreFailure(_ error: Error) async {
        if let retryDelay = retryDelaySeconds(for: error) {
            fetchCooldownUntil = Date().addingTimeInterval(retryDelay)
        }
        if totalAvailableReels(after: currentVisibleIndex) > 0 {
            logger.warning(
                "Feed background fetch failed but buffer remains usable - visibleIndex: \(currentVisibleIndex), visibleTotal: \(phrases.count), queued: \(queuedPhrases.count), error: \(error.localizedDescription)"
            )
            tailState = .idle
            if fetchCooldownUntil == nil {
                fetchCooldownUntil = Date().addingTimeInterval(lowYieldFetchCooldown)
            }
            return
        }
        guard shouldRetryLoadMore(after: error) else {
            tailState = .failed(message: UserFacingMessageMapper.localizedErrorMessage(for: error))
            return
        }
        await retryFetchMoreAfterConnectionDrop()
    }

    private func retryFetchMoreAfterConnectionDrop() async {
        let deadline = Date().addingTimeInterval(12)
        while Date() < deadline {
            if Task.isCancelled {
                tailState = .idle
                return
            }
            let remaining = max(Int(ceil(deadline.timeIntervalSinceNow)), 0)
            tailState = .reconnecting(remainingSeconds: remaining)
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                try await fetchMorePhrases(force: true)
                tailState = .idle
                return
            } catch {
                guard shouldRetryLoadMore(after: error) else {
                    tailState = .failed(message: UserFacingMessageMapper.localizedErrorMessage(for: error))
                    return
                }
            }
        }
        tailState = .failed(message: LocalizedStrings.feedErrorDescription)
    }

    private func shouldRetryLoadMore(after error: Error) -> Bool {
        if error is PaginationError {
            return false
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return true
            case .timedOut:
                return false
            default:
                return false
            }
        }

        if let serviceError = error as? AIServiceError {
            if case let .networkError(message) = serviceError {
                let normalized = message.lowercased()
                if normalized.contains("timed out") || normalized.contains("timeout") {
                    return false
                }
                if normalized.contains("quota") || normalized.contains("resource_exhausted") || normalized.contains("rate limit") || normalized.contains("retry in") {
                    return false
                }
                if normalized.contains("not connected") ||
                    normalized.contains("network connection") ||
                    normalized.contains("cannot find host") ||
                    normalized.contains("cannot connect to host") ||
                    normalized.contains("dns") {
                    return true
                }
            }
        }

        return false
    }

    private func retryDelaySeconds(for error: Error) -> TimeInterval? {
        let rawMessage: String
        if let serviceError = error as? AIServiceError {
            switch serviceError {
            case .networkError(let message), .decodingError(let message):
                rawMessage = message
            case .invalidAPIKey, .unauthenticated:
                return nil
            }
        } else {
            rawMessage = error.localizedDescription
        }

        let lowered = rawMessage.lowercased()
        guard lowered.contains("retry in") || lowered.contains("retry after") || lowered.contains("quota") || lowered.contains("resource_exhausted") || lowered.contains("rate limit") else {
            return nil
        }

        if let regex = try? NSRegularExpression(pattern: "retry (?:in|after) ([0-9]+(?:\\.[0-9]+)?)s", options: [.caseInsensitive]) {
            let range = NSRange(rawMessage.startIndex..<rawMessage.endIndex, in: rawMessage)
            if let match = regex.firstMatch(in: rawMessage, options: [], range: range),
               match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: rawMessage),
               let seconds = Double(rawMessage[captureRange]) {
                return max(seconds, lowYieldFetchCooldown)
            }
        }

        return max(15, lowYieldFetchCooldown)
    }

    private func remainingReels(after index: Int) -> Int {
        guard !phrases.isEmpty else { return 0 }
        let clampedIndex = max(0, min(index, phrases.count))
        return max(phrases.count - clampedIndex - 1, 0)
    }

    private func totalAvailableReels(after index: Int) -> Int {
        remainingReels(after: index) + queuedPhrases.count
    }

    private func canStartAutomaticFetch(triggeredByTail: Bool) -> Bool {
        if let fetchCooldownUntil, Date() < fetchCooldownUntil {
            return false
        }
        if let lastAutomaticFetchAt,
           Date().timeIntervalSince(lastAutomaticFetchAt) < minimumAutomaticFetchSpacing {
            return false
        }
        return true
    }

    private func recommendedFetchCount(currentIndex: Int) -> Int {
        let totalAvailable = totalAvailableReels(after: currentIndex)
        let missingToTarget = max(targetBufferSize - totalAvailable, 0)
        if lastFetchAddedCount > 0 && lastFetchAddedCount < lowWatermark {
            return max(refillSize, 40)
        }
        return max(refillSize, min(max(refillSize, missingToTarget), 48))
    }

    private func isAcceptableFeedPhrase(_ phrase: EnglishPhrase) -> Bool {
        let text = phrase.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }

        let charCount = text.count
        let wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
        let policy = contentPolicy
        let relaxedMinChars = max(80, policy.minChars - 35)
        let relaxedMaxChars = policy.maxChars + 120
        let relaxedMinWords = max(12, policy.minWords - 4)
        let relaxedMaxWords = policy.maxWords + 20

        return charCount >= relaxedMinChars &&
            charCount <= relaxedMaxChars &&
            wordCount >= relaxedMinWords &&
            wordCount <= relaxedMaxWords
    }

    private func deduplicate(_ items: [EnglishPhrase]) -> [EnglishPhrase] {
        var seen = Set<String>()
        var unique: [EnglishPhrase] = []
        for item in items {
            let key = dedupeKey(for: item)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(item)
        }
        return unique
    }

    private func dedupeKey(for phrase: EnglishPhrase) -> String {
        if !phrase.reelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "reel:\(phrase.reelID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
        }
        return "text:\(normalize(phrase.text))"
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

    private func generateBatch(excludedTexts: [String], count: Int? = nil, requestID: String? = nil) async throws -> GeneratedPhraseBatch {
        let effectiveInterests = Array(Set(userInterests + favoriteCategories)).sorted()
        let policy = contentPolicy
        return try await aiService.generatePhrases(
            level: userLevel,
            nativeLanguage: userNativeLanguage,
            interests: effectiveInterests,
            objectives: userObjectives,
            count: count ?? refillSize,
            excludedTexts: excludedTexts,
            minWordsPerCard: policy.minWords,
            maxWordsPerCard: policy.maxWords,
            minCharactersPerCard: policy.minChars,
            maxCharactersPerCard: policy.maxChars,
            preferredSentenceRange: policy.preferredSentenceRange,
            requestID: requestID
        )
    }

    private func ingestIncoming(_ items: [EnglishPhrase], source: String) -> Int {
        let uniqueIncoming = deduplicate(items)
        var appended = 0
        var deduplicated = 0
        for item in uniqueIncoming where isAcceptableFeedPhrase(item) {
            let key = dedupeKey(for: item)
            guard !key.isEmpty else { continue }
            if seenPhraseKeys.insert(key).inserted {
                queuedPhrases.append(item)
                appended += 1
            } else {
                deduplicated += 1
            }
        }
        bufferedPhraseCount = queuedPhrases.count
        logger.info(
            "Feed buffer ingest - source: \(source), incoming: \(items.count), appendedToQueue: \(appended), deduplicated: \(deduplicated), queuedNow: \(queuedPhrases.count)"
        )
        return appended
    }

    private func promoteBufferedPhrasesIfNeeded(trigger: String, desiredVisibleRemaining: Int) -> Int {
        guard !queuedPhrases.isEmpty else {
            bufferedPhraseCount = 0
            return 0
        }
        let remainingVisible = remainingReels(after: currentVisibleIndex)
        let needed = max(desiredVisibleRemaining - remainingVisible, 0)
        guard needed > 0 else {
            bufferedPhraseCount = queuedPhrases.count
            return 0
        }

        let promotedCount = min(needed, queuedPhrases.count)
        let promoted = Array(queuedPhrases.prefix(promotedCount))
        queuedPhrases.removeFirst(promotedCount)
        phrases.append(contentsOf: promoted)
        bufferedPhraseCount = queuedPhrases.count
        logger.info(
            "Feed buffer promote - trigger: \(trigger), promoted: \(promotedCount), visibleNow: \(phrases.count), queuedRemaining: \(queuedPhrases.count)"
        )
        return promotedCount
    }

    private func allKnownTexts() -> [String] {
        (phrases + queuedPhrases).map(\.text)
    }

    private func resetFeedState() {
        phrases = []
        queuedPhrases = []
        seenPhraseKeys = []
        currentVisibleIndex = 0
        lastAutomaticFetchAt = nil
        lastFetchAddedCount = 0
        activeFetchRequestID = nil
        fetchCooldownUntil = nil
        furthestConsumedIndex = 0
        firstBlockingLoadingLogged = false
        bufferedPhraseCount = 0
        isBackgroundFetching = false
        tailState = .idle
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

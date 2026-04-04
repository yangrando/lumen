import SwiftUI
import SwiftData

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var audioService = AudioService.shared
    @StateObject private var sessionService = SessionService.shared
    @StateObject private var reelInteractionService = ReelInteractionService.shared
    @StateObject private var xpTracker = XPTracker.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoritePhrase.dateSaved, order: .reverse) private var favorites: [FavoritePhrase]
    @State private var currentPage = 0
    @State private var showProfile = false
    @State private var showSavedPhrases = false
    @State private var askAIPhrase: EnglishPhrase?
    @State private var speakingPhrase: EnglishPhrase?
    @State private var feedbackMessage: AppFeedbackMessage?
    @State private var currentTrackedReelID: String?
    @State private var currentTrackedPhrase: EnglishPhrase?
    @State private var currentReelStartedAt = Date()
    @State private var viewedReelsInSession = Set<String>()

    private var currentUserID: String? {
        sessionService.currentUser?.sub
    }

    private var scopedFavorites: [FavoritePhrase] {
        guard let currentUserID else {
            return favorites.filter { $0.userID == nil }
        }
        return favorites.filter { $0.userID == currentUserID }
    }
    
    var body: some View {
        if !sessionService.isAuthenticated {
            OnboardingView()
        } else {
        ZStack {
            // Background
            LumenColors.navyDark
                .ignoresSafeArea()
            
            // Content
            if viewModel.isLoading && viewModel.phrases.isEmpty {
                if sessionService.justCompletedOnboarding {
                    OnboardingCompletionView(autoAdvance: false)
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)

                        Text(LocalizedStrings.feedLoadingTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(LocalizedStrings.feedLoadingDescription)
                            .font(.system(size: 14))
                            .foregroundStyle(LumenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                }
            } else if let errorMessage = viewModel.errorMessage {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)
                    
                    Text(LocalizedStrings.feedErrorTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        Task {
                            await viewModel.loadPhrases()
                        }
                    }) {
                        Text(LocalizedStrings.feedErrorRetry)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 16)
                }
                .frame(maxHeight: .infinity)
                .padding(16)
            } else if !viewModel.phrases.isEmpty {
                // Feed with phrases
                VerticalPageView(
                    pages: feedPages,
                    currentPage: $currentPage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
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

            if !viewModel.isLoading && viewModel.errorMessage == nil && !viewModel.phrases.isEmpty {
                VStack {
                    Spacer()

                    bottomNavigationBar
                        .padding(.horizontal, 84)
                        .padding(.bottom, 26)
                }
                .ignoresSafeArea()
            }

            VStack(spacing: 10) {
                ForEach(xpTracker.floatingRewards) { reward in
                    Text(reward.label)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 0.50, green: 0.93, blue: 0.72))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.28))
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 120)
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: xpTracker.floatingRewards)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showProfile) {
            if let token = sessionService.accessToken {
                ProfileView(
                    accessToken: token,
                    onClose: {
                        showProfile = false
                    }
                )
            }
        }
        .sheet(isPresented: $showSavedPhrases) {
            NavigationStack {
                SavedPhrasesView()
            }
        }
        .onChange(of: showProfile) { _, isPresented in
            if isPresented {
                viewModel.cancelLoadMore()
            }
        }
        .onChange(of: showSavedPhrases) { _, isPresented in
            if isPresented {
                viewModel.cancelLoadMore()
            }
        }
        .sheet(item: $askAIPhrase) { phrase in
            AskAIView(
                phrase: phrase,
                onAsk: { question in
                    await viewModel.askAI(phrase: phrase.text, question: question)
                },
                onOpen: {
                    Task {
                        await TrackingService.shared.track(
                            event: .aiHelpOpened,
                            reelID: phrase.trackingReelID,
                            sessionType: .feed,
                            metadata: trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
                        )
                    }
                },
                onSubmitQuestion: { question in
                    let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await TrackingService.shared.track(
                            event: .aiHelpSubmitted,
                            reelID: phrase.trackingReelID,
                            sessionType: .feed,
                            metadata: trackingMetadata(
                                for: phrase,
                                extra: [
                                    "surface": .string("feed"),
                                    "question_length": .int(question.count)
                                ]
                            )
                        )
                        if !trimmedQuestion.isEmpty {
                            registerLearningAction(.askAI, for: phrase)
                        }
                    }
                },
                onSpeakingStarted: {
                    Task {
                        _ = await TrackingService.shared.startSession(.speaking, metadata: ["source": .string("ask_ai")])
                        await TrackingService.shared.track(
                            event: .speakingStarted,
                            reelID: phrase.trackingReelID,
                            sessionType: .speaking,
                            metadata: trackingMetadata(for: phrase, extra: ["surface": .string("ask_ai")])
                        )
                    }
                },
                onSpeakingCompleted: { transcript in
                    Task {
                        await TrackingService.shared.track(
                            event: .speakingCompleted,
                            reelID: phrase.trackingReelID,
                            sessionType: .speaking,
                            metadata: trackingMetadata(
                                for: phrase,
                                extra: [
                                    "surface": .string("ask_ai"),
                                    "transcript_length": .int(transcript.count)
                                ]
                            )
                        )
                        await TrackingService.shared.endSession(
                            .speaking,
                            metadata: ["reason": .string("recording_stopped")]
                        )
                    }
                }
            )
        }
        .sheet(item: $speakingPhrase) { phrase in
            if let accessToken = sessionService.accessToken {
                SpeakingPracticeView(
                    title: "Speak This Reel",
                    accessToken: accessToken,
                    targetText: phrase.text,
                    reelID: phrase.trackingReelID,
                    reviewItemID: nil,
                    onAppearTrack: {
                        Task {
                            _ = await TrackingService.shared.startSession(.speaking, metadata: ["source": .string("reel_speaking")])
                            await TrackingService.shared.track(
                                event: .speakingStarted,
                                reelID: phrase.trackingReelID,
                                sessionType: .speaking,
                                metadata: trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
                            )
                        }
                    },
                    onDisappearTrack: {
                        Task {
                            await TrackingService.shared.endSession(.speaking, metadata: ["reason": .string("speaking_sheet_closed")])
                        }
                    },
                    onCompleted: { _ in
                        registerLearningAction(.speak, for: phrase)
                    }
                )
            }
        }
        .onChange(of: askAIPhrase?.id) { _, newValue in
            if newValue != nil {
                viewModel.cancelLoadMore()
            }
        }
        .onChange(of: speakingPhrase?.id) { _, newValue in
            if newValue != nil {
                viewModel.cancelLoadMore()
            }
        }
        .appFeedbackBanner($feedbackMessage)
        .onDisappear {
            audioService.stop()
        }
        .onAppear {
            viewedReelsInSession.removeAll()
            Task {
                await sessionService.ensureCurrentUserLoaded()
                reelInteractionService.load(for: currentUserID)
                xpTracker.load(for: currentUserID)
                await syncSavedReels()
                viewModel.updateFavoriteSignals(from: scopedFavorites)
                _ = await TrackingService.shared.startSession(.feed, metadata: ["source": .string("main_feed")])
            }
        }
        .onChange(of: favorites.count) { _, _ in
            viewModel.updateFavoriteSignals(from: scopedFavorites)
        }
        .onChange(of: viewModel.phrases.count) { _, count in
            // +1 tail page always exists at index == count.
            currentPage = min(currentPage, count)
            viewModel.prefetchBackgrounds(around: currentPage)
        }
        .onChange(of: currentPage) { _, newPage in
            flushCurrentReelTime()
            trackVisibleReel(at: newPage)
            viewModel.ensureMorePhrasesIfNeeded(currentIndex: newPage)
            viewModel.prefetchBackgrounds(around: newPage)
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if !isLoading && sessionService.justCompletedOnboarding {
                sessionService.justCompletedOnboarding = false
            }
            if !isLoading {
                trackVisibleReel(at: currentPage)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                flushCurrentReelTime()
            } else if newPhase == .active {
                trackVisibleReel(at: currentPage)
            }
            Task {
                await TrackingService.shared.handleScenePhaseChange(newPhase)
            }
        }
        .onDisappear {
            flushCurrentReelTime()
            viewedReelsInSession.removeAll()
            Task {
                await TrackingService.shared.endSession(.feed, metadata: ["reason": .string("feed_closed")])
            }
        }
    }
    }

    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            navItem(
                title: "FEED",
                systemImage: "newspaper.fill",
                isActive: true,
                action: {}
            )

            navItem(
                title: "SAVED",
                systemImage: "bookmark.fill",
                isActive: false,
                action: {
                    showSavedPhrases = true
                }
            )

            Button {
                showProfile = true
            } label: {
                navItemLabel(
                    title: "PROFILE",
                    systemImage: "person.fill",
                    isActive: false
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            Capsule()
                .fill(Color(red: 0.05, green: 0.12, blue: 0.23).opacity(0.86))
        )
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.20), radius: 18, x: 0, y: 12)
    }

    private func navItem(
        title: String,
        systemImage: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            navItemLabel(title: title, systemImage: systemImage, isActive: isActive)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func navItemLabel(
        title: String,
        systemImage: String,
        isActive: Bool
    ) -> some View {
        VStack(spacing: 0) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    isActive
                    ? Color(red: 0.19, green: 0.84, blue: 0.98)
                    : Color(red: 0.46, green: 0.52, blue: 0.65)
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 30)
    }

    private var feedPages: [AnyView] {
        let phrasePages = viewModel.phrases.map { phrase in
            AnyView(
                Group {
                    if viewModel.isBackgroundReady(for: phrase.id) {
                        PhraseCard(
                            phrase: phrase,
                            backgroundImageURL: viewModel.backgroundURLs[phrase.id],
                            isSaved: isPhraseSaved(phrase),
                            isAudioPlaying: audioService.currentlyPlayingPhraseID == phrase.id,
                            learningState: reelInteractionService.state(for: phrase.trackingReelID),
                            highlightedTokens: highlightedTokens(for: phrase),
                            currentUserID: currentUserID,
                            onPlayAudio: {
                                if audioService.currentlyPlayingPhraseID != phrase.id {
                                    Task {
                                        await TrackingService.shared.track(
                                            event: .audioPlayed,
                                            reelID: phrase.trackingReelID,
                                            sessionType: .feed,
                                            metadata: trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
                                        )
                                    }
                                    registerLearningAction(.listen, for: phrase)
                                }
                                audioService.togglePlayback(for: phrase.id, text: phrase.text)
                            },
                            onSpeak: {
                                speakingPhrase = phrase
                            },
                            onTranslationOpened: {
                                Task {
                                    await TrackingService.shared.track(
                                        event: .translationOpened,
                                        reelID: phrase.trackingReelID,
                                        sessionType: .feed,
                                        metadata: trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
                                    )
                                }
                                registerLearningAction(.translate, for: phrase)
                            },
                            onAskAI: {
                                askAIPhrase = phrase
                            },
                            onSave: {
                                toggleFavorite(phrase)
                            }
                        )
                    } else {
                        reelLoadingPage
                    }
                }
            )
        }

        return phrasePages + [AnyView(tailPage)]
    }

    private var reelLoadingPage: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)

                Text(LocalizedStrings.feedLoadingTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text(LocalizedStrings.feedLoadingDescription)
                    .font(.system(size: 14))
                    .foregroundStyle(LumenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var tailPage: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            VStack(spacing: 14) {
                switch viewModel.tailState {
                case .loading:
                    ProgressView()
                        .tint(.white)
                    Text(LocalizedStrings.feedLoadingTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(LocalizedStrings.feedLoadingDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)

                case .idle:
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(LocalizedStrings.feedTailIdleTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(LocalizedStrings.feedTailIdleDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        viewModel.retryLoadMore()
                    } label: {
                        Text(LocalizedStrings.feedTailIdleAction)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 6)

                case .reconnecting(let remainingSeconds):
                    ProgressView()
                        .tint(.white)
                    Text(LocalizedStrings.feedLoadingTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("\(LocalizedStrings.feedLoadingDescription) (\(remainingSeconds)s)")
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)

                case .failed(let message):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.yellow)
                    Text(LocalizedStrings.feedErrorTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        viewModel.retryLoadMore()
                    } label: {
                        Text(LocalizedStrings.feedErrorRetry)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 22)
            .onAppear {
                if case .idle = viewModel.tailState {
                    viewModel.ensureMorePhrasesIfNeeded(currentIndex: viewModel.phrases.count)
                }
            }
        }
    }

    private func isPhraseSaved(_ phrase: EnglishPhrase) -> Bool {
        scopedFavorites.contains { $0.reelID == phrase.trackingReelID }
    }

    private func toggleFavorite(_ phrase: EnglishPhrase) {
        Task {
            await sessionService.ensureCurrentUserLoaded()
            guard let userID = sessionService.currentUser?.sub else {
                feedbackMessage = AppFeedbackMessage(
                    title: LocalizedStrings.feedbackErrorTitle,
                    message: LocalizedStrings.commonErrorUnauthenticated,
                    tone: .error
                )
                return
            }

            if let existing = scopedFavorites.first(where: { $0.reelID == phrase.trackingReelID }) {
                modelContext.delete(existing)
                do {
                    try modelContext.save()
                    await SavedReelsService.shared.enqueueUnsave(userID: userID, reelID: phrase.trackingReelID)
                    await syncSavedReels()
                    await AppFeedbackPresenter.show(
                        UserFacingMessageMapper.successFeedback(message: LocalizedStrings.savedReelsRemoved),
                        in: $feedbackMessage
                    )
                } catch {
                    feedbackMessage = UserFacingMessageMapper.errorFeedback(error)
                }
                return
            }

            Task {
                await TrackingService.shared.track(
                    event: .saved,
                    reelID: phrase.trackingReelID,
                    sessionType: .feed,
                    metadata: trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
                )
            }

            modelContext.insert(
                FavoritePhrase(
                    reelID: phrase.trackingReelID,
                    userID: userID,
                    text: phrase.text,
                    translation: phrase.translation,
                    category: phrase.category,
                    difficulty: phrase.difficulty.rawValue,
                    isPendingSync: true
                )
            )

            do {
                try modelContext.save()
                await SavedReelsService.shared.enqueueSave(userID: userID, phrase: phrase)
                await syncSavedReels()
                await AppFeedbackPresenter.show(
                    UserFacingMessageMapper.successFeedback(message: LocalizedStrings.savedReelsSaved),
                    in: $feedbackMessage
                )
            } catch {
                feedbackMessage = UserFacingMessageMapper.errorFeedback(error)
            }
        }
    }

    private func highlightedTokens(for phrase: EnglishPhrase) -> [HighlightedWord] {
        WordHighlightService.highlightedTokens(for: phrase)
    }

    private func registerLearningAction(_ action: ReelLearningAction, for phrase: EnglishPhrase) {
        let result = reelInteractionService.register(action, for: phrase.trackingReelID, userID: currentUserID)
        if result.wasNew {
            _ = xpTracker.award(for: action, userID: currentUserID)
        }
        if result.completedNow {
            Task { @MainActor in
                await AppFeedbackPresenter.show(
                    AppFeedbackMessage(
                        title: LocalizedStrings.feedbackSuccessTitle,
                        message: NativeLanguageLocalization.localizedString(forKey: "reel.completed.message", fallback: "Reel completed."),
                        tone: .success
                    ),
                    in: $feedbackMessage,
                    durationNanoseconds: 1_100_000_000
                )
            }
        }
    }

    @MainActor
    private func syncSavedReels() async {
        guard let accessToken = sessionService.accessToken else { return }
        await sessionService.ensureCurrentUserLoaded()
        guard let userID = sessionService.currentUser?.sub else { return }

        do {
            if !SavedReelsLocalCache.hasCompletedLegacyMigration(for: userID) {
                let legacyItems = favorites.filter { $0.userID == nil }
                if !legacyItems.isEmpty {
                    let migrated = try await SavedReelsService.shared.migrateLegacyFavorites(
                        accessToken: accessToken,
                        items: legacyItems.map {
                            SavedReelMigrationItem(
                                reelID: $0.reelID.isEmpty ? $0.trackingReelID : $0.reelID,
                                text: $0.text,
                                translation: $0.translation,
                                category: $0.category,
                                difficulty: $0.difficulty
                            )
                        }
                    )
                    for item in legacyItems {
                        modelContext.delete(item)
                    }
                    try modelContext.save()
                    try SavedReelsLocalCache.reconcile(modelContext: modelContext, currentUserID: userID, remoteItems: migrated)
                }
                SavedReelsLocalCache.markLegacyMigrationCompleted(for: userID)
            }

            await SavedReelsService.shared.flushPending(accessToken: accessToken, userID: userID)
            let pendingSaveReelIDs = await SavedReelsService.shared.pendingSaveReelIDs(for: userID)
            let remoteItems = try await SavedReelsService.shared.fetchSavedReels(accessToken: accessToken)
            try SavedReelsLocalCache.reconcile(
                modelContext: modelContext,
                currentUserID: userID,
                remoteItems: remoteItems,
                preservingPendingSaveReelIDs: pendingSaveReelIDs
            )
        } catch {
            Logger.shared.warning("Saved reels sync failed: \(error.localizedDescription)")
            feedbackMessage = AppFeedbackMessage(
                title: LocalizedStrings.feedbackErrorTitle,
                message: LocalizedStrings.savedReelsSyncError,
                tone: .error
            )
        }
    }

    private func trackVisibleReel(at page: Int) {
        guard !viewModel.isLoading, page >= 0, page < viewModel.phrases.count else { return }
        let phrase = viewModel.phrases[page]
        let reelID = phrase.trackingReelID
        currentTrackedReelID = reelID
        currentTrackedPhrase = phrase
        currentReelStartedAt = Date()

        guard !viewedReelsInSession.contains(reelID) else {
            Task {
                await TrackingService.shared.heartbeatSession(.feed, metadata: [
                    "page_index": .int(page),
                    "reel_id": .string(reelID)
                ])
            }
            return
        }

        viewedReelsInSession.insert(reelID)
        Task {
            await TrackingService.shared.track(
                event: .viewed,
                reelID: reelID,
                sessionType: .feed,
                metadata: trackingMetadata(for: phrase, extra: [
                    "page_index": .int(page)
                ])
            )
            await TrackingService.shared.heartbeatSession(.feed, metadata: [
                "page_index": .int(page),
                "reel_id": .string(reelID)
            ], force: true)
        }
    }

    private func flushCurrentReelTime() {
        guard let reelID = currentTrackedReelID else { return }
        let durationMS = max(Int(Date().timeIntervalSince(currentReelStartedAt) * 1000), 0)
        guard durationMS > 250 else {
            currentTrackedReelID = nil
            currentTrackedPhrase = nil
            currentReelStartedAt = Date()
            return
        }

        let trackedPhrase = currentTrackedPhrase
        Task {
            await TrackingService.shared.track(
                event: .timeSpent,
                reelID: reelID,
                sessionType: .feed,
                durationMS: durationMS,
                metadata: trackedPhrase.map { trackingMetadata(for: $0, extra: ["surface": .string("feed")]) } ?? ["surface": .string("feed")]
            )
        }
        currentTrackedReelID = nil
        currentTrackedPhrase = nil
        currentReelStartedAt = Date()
    }

    private func trackingMetadata(for phrase: EnglishPhrase, extra: TrackingMetadata = [:]) -> TrackingMetadata {
        var metadata: TrackingMetadata = [
            "text": .string(phrase.text),
            "translation": .string(phrase.translation),
            "category": .string(phrase.category),
            "difficulty": .string(phrase.difficulty.rawValue)
        ]
        if let goal = phrase.goal, !goal.isEmpty {
            metadata["goal"] = .string(goal)
        }
        if let contentType = phrase.contentType, !contentType.isEmpty {
            metadata["content_type"] = .string(contentType)
        }
        if let grammarFocus = phrase.grammarFocus, !grammarFocus.isEmpty {
            metadata["grammar_focus"] = .string(grammarFocus)
        }
        if !phrase.keywords.isEmpty {
            metadata["keywords"] = .string(phrase.keywords.joined(separator: ", "))
        }
        if !phrase.focusWords.isEmpty {
            metadata["focus_words"] = .string(phrase.focusWords.joined(separator: ", "))
        }
        metadata["speaking_suitable"] = .bool(phrase.speakingSuitable)
        if let reviewPriorityHint = phrase.reviewPriorityHint, !reviewPriorityHint.isEmpty {
            metadata["review_priority_hint"] = .string(reviewPriorityHint)
        }
        if let difficultyMode = phrase.difficultyMode, !difficultyMode.isEmpty {
            metadata["difficulty_mode"] = .string(difficultyMode)
        }
        extra.forEach { metadata[$0.key] = $0.value }
        return metadata
    }

}

#Preview {
    NavigationStack {
        FeedView()
    }
}

// MARK: - Vertical Page View (UIViewControllerRepresentable)

struct VerticalPageView<Page: View>: UIViewControllerRepresentable {
    var pages: [Page]
    @Binding var currentPage: Int
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical
        )
        context.coordinator.pageViewController = controller
        controller.view.backgroundColor = .clear
        controller.view.isOpaque = false
        controller.view.insetsLayoutMarginsFromSafeArea = false
        controller.additionalSafeAreaInsets = .zero
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        for subview in controller.view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollView.backgroundColor = .clear
                scrollView.isOpaque = false
                scrollView.contentInsetAdjustmentBehavior = .never
            }
        }
        if !context.coordinator.controllers.isEmpty {
            controller.setViewControllers(
                [context.coordinator.controllers[currentPage]],
                direction: .forward,
                animated: false
            )
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.pageViewController = uiViewController
        let rebuiltControllers = context.coordinator.updateControllers(with: pages)
        
        guard !context.coordinator.controllers.isEmpty else { return }
        let safePage = min(max(currentPage, 0), context.coordinator.controllers.count - 1)
        if context.coordinator.isTransitioning {
            context.coordinator.pendingPage = safePage
            return
        }
        if safePage == context.coordinator.currentPage {
            if rebuiltControllers,
               let visible = uiViewController.viewControllers?.first,
               let visibleIndex = context.coordinator.indexOfControllerIdentity(visible),
               visibleIndex == safePage {
                uiViewController.setViewControllers(
                    [visible],
                    direction: .forward,
                    animated: false
                )
            }
            return
        }
        
        let direction: UIPageViewController.NavigationDirection =
            safePage >= context.coordinator.currentPage ? .forward : .reverse
        
        uiViewController.setViewControllers(
            [context.coordinator.controllers[safePage]],
            direction: direction,
            animated: true
        )
        
        context.coordinator.currentPage = safePage
    }
    
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: VerticalPageView
        var controllers: [UIViewController]
        var currentPage: Int
        weak var pageViewController: UIPageViewController?
        var isTransitioning = false
        var pendingPage: Int?
        
        init(_ parent: VerticalPageView) {
            self.parent = parent
            self.controllers = parent.pages.map { Self.makeHostingController(rootView: $0) }
            self.currentPage = parent.currentPage
        }
        
        func updateControllers(with pages: [Page]) -> Bool {
            var rebuilt = false

            if controllers.count < pages.count {
                let additional = pages[controllers.count...].map { Self.makeHostingController(rootView: $0) }
                controllers.append(contentsOf: additional)
                rebuilt = true
            } else if controllers.count > pages.count {
                controllers.removeLast(controllers.count - pages.count)
                rebuilt = true
            }

            for index in pages.indices {
                if let hosting = controllers[index] as? UIHostingController<Page> {
                    hosting.rootView = pages[index]
                    hosting.view.backgroundColor = .clear
                }
            }
            return rebuilt
        }

        func indexOfControllerIdentity(_ viewController: UIViewController) -> Int? {
            controllers.firstIndex(where: { $0 === viewController })
        }
        
        private static func makeHostingController(rootView: Page) -> UIViewController {
            let hosting = UIHostingController(rootView: rootView)
            hosting.view.backgroundColor = .clear
            hosting.view.isOpaque = false
            hosting.additionalSafeAreaInsets = .zero
            if #available(iOS 16.4, *) {
                hosting.safeAreaRegions = []
            }
            return hosting
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard
                let index = controllers.firstIndex(where: { $0 === viewController }),
                index > 0
            else { return nil }
            return controllers[index - 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard
                let index = controllers.firstIndex(where: { $0 === viewController }),
                index + 1 < controllers.count
            else { return nil }
            return controllers[index + 1]
        }
        
        func pageViewController(
            _ pageViewController: UIPageViewController,
            willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            isTransitioning = true
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            isTransitioning = false
            guard
                completed,
                let visible = pageViewController.viewControllers?.first,
                let index = controllers.firstIndex(where: { $0 === visible })
            else {
                applyPendingPageIfNeeded()
                return
            }
            currentPage = index
            parent.currentPage = index
            applyPendingPageIfNeeded()
        }

        private func applyPendingPageIfNeeded() {
            guard
                let pageViewController,
                let pendingPage
            else { return }

            let safePendingPage = min(max(pendingPage, 0), controllers.count - 1)
            self.pendingPage = nil

            guard safePendingPage != currentPage else { return }

            let direction: UIPageViewController.NavigationDirection =
                safePendingPage >= currentPage ? .forward : .reverse

            pageViewController.setViewControllers(
                [controllers[safePendingPage]],
                direction: direction,
                animated: false
            )
            currentPage = safePendingPage
            parent.currentPage = safePendingPage
        }
    }
}

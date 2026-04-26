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
                            .font(LumenFont.grotesk(18, weight: .semibold))
                            .foregroundStyle(LumenColors.ink50)

                        Text(LocalizedStrings.feedLoadingDescription)
                            .font(LumenFont.grotesk(14))
                            .foregroundStyle(LumenColors.ink300)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                }
            } else if let errorMessage = viewModel.errorMessage {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(LumenFont.grotesk(48))
                        .foregroundStyle(.red)

                    Text(LocalizedStrings.feedErrorTitle)
                        .font(LumenFont.grotesk(18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)

                    Text(errorMessage)
                        .font(LumenFont.grotesk(14))
                        .foregroundStyle(LumenColors.ink300)
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
                        .font(LumenFont.grotesk(48))
                        .foregroundStyle(LumenColors.textSecondary)
                    
                    Text(LocalizedStrings.feedEmptyTitle)
                        .font(LumenFont.grotesk(18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)

                    Text(LocalizedStrings.feedEmptyDescription)
                        .font(LumenFont.grotesk(14))
                        .foregroundStyle(LumenColors.ink300)
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
                        .font(LumenFont.grotesk(20, weight: .bold))
                        .foregroundStyle(LumenColors.good)
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
                            metadata: viewModel.trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
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
                            metadata: viewModel.trackingMetadata(
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
                            metadata: viewModel.trackingMetadata(for: phrase, extra: ["surface": .string("ask_ai")])
                        )
                    }
                },
                onSpeakingCompleted: { transcript in
                    Task {
                        await TrackingService.shared.track(
                            event: .speakingCompleted,
                            reelID: phrase.trackingReelID,
                            sessionType: .speaking,
                            metadata: viewModel.trackingMetadata(
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
                    title: LocalizedStrings.feedSpeakThisReel,
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
                                metadata: viewModel.trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
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
            viewModel.resetSession()
            Task {
                await sessionService.ensureCurrentUserLoaded()
                // currentUserID is safe to use only after ensureCurrentUserLoaded completes.
                // Log if still nil so we can catch the failure during development.
                if sessionService.currentUser == nil {
                    Logger.shared.warning("FeedView.onAppear: currentUser is nil after ensureCurrentUserLoaded — user-specific features disabled")
                }
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
            viewModel.flushCurrentReelTime()
            viewModel.trackVisibleReel(at: newPage)
            viewModel.ensureMorePhrasesIfNeeded(currentIndex: newPage)
            viewModel.prefetchBackgrounds(around: newPage)
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if !isLoading && sessionService.justCompletedOnboarding {
                sessionService.justCompletedOnboarding = false
            }
            if !isLoading {
                viewModel.trackVisibleReel(at: currentPage)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.flushCurrentReelTime()
            } else if newPhase == .active {
                viewModel.trackVisibleReel(at: currentPage)
            }
            Task {
                await TrackingService.shared.handleScenePhaseChange(newPhase)
            }
        }
        .onDisappear {
            viewModel.flushCurrentReelTime()
            viewModel.resetSession()
            Task {
                await TrackingService.shared.endSession(.feed, metadata: ["reason": .string("feed_closed")])
            }
        }
    }
    }

    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            navItem(
                title: LocalizedStrings.feedTabFeed,
                systemImage: "newspaper.fill",
                isActive: true,
                action: {}
            )

            navItem(
                title: LocalizedStrings.feedTabSaved,
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
                    title: LocalizedStrings.feedTabProfile,
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
                .fill(LumenColors.ink800.opacity(0.92))
        )
        .overlay {
            Capsule()
                .stroke(LumenColors.ink700, lineWidth: 1)
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
                .font(LumenFont.grotesk(18, weight: .semibold))
                .foregroundStyle(
                    isActive
                    ? LumenColors.accent
                    : LumenColors.ink400
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
                                            metadata: viewModel.trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
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
                                        metadata: viewModel.trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
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
                    .font(LumenFont.grotesk(18, weight: .semibold))
                    .foregroundStyle(LumenColors.ink50)

                Text(LocalizedStrings.feedLoadingDescription)
                    .font(LumenFont.grotesk(14))
                    .foregroundStyle(LumenColors.ink300)
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
                        .font(LumenFont.grotesk(18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)
                    Text(LocalizedStrings.feedLoadingDescription)
                        .font(LumenFont.grotesk(14))
                        .foregroundStyle(LumenColors.ink300)
                        .multilineTextAlignment(.center)

                case .idle:
                    Image(systemName: "arrow.up.circle")
                        .font(LumenFont.grotesk(36))
                        .foregroundStyle(LumenColors.ink200)
                    Text(LocalizedStrings.feedTailIdleTitle)
                        .font(LumenFont.grotesk(18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)
                    Text(LocalizedStrings.feedTailIdleDescription)
                        .font(LumenFont.grotesk(14))
                        .foregroundStyle(LumenColors.ink300)
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
                        .font(LumenFont.grotesk(18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)
                    Text("\(LocalizedStrings.feedLoadingDescription) (\(remainingSeconds)s)")
                        .font(LumenFont.grotesk(14))
                        .foregroundStyle(LumenColors.ink300)
                        .multilineTextAlignment(.center)

                case .failed(let message):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(LumenFont.grotesk(36))
                        .foregroundStyle(LumenColors.warn)
                    Text(LocalizedStrings.feedErrorTitle)
                        .font(LumenFont.grotesk(18, weight: .semibold))
                        .foregroundStyle(LumenColors.ink50)
                    Text(message)
                        .font(LumenFont.grotesk(14))
                        .foregroundStyle(LumenColors.ink300)
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
                    metadata: viewModel.trackingMetadata(for: phrase, extra: ["surface": .string("feed")])
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
            NotificationCenter.default.post(name: .progressOverviewShouldRefresh, object: nil)
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

}

#Preview {
    NavigationStack {
        FeedView()
    }
}


import SwiftUI
import SwiftData

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var audioService = AudioService.shared
    @StateObject private var sessionService = SessionService.shared
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoritePhrase.dateSaved, order: .reverse) private var favorites: [FavoritePhrase]
    @State private var currentPage = 0
    @State private var showProfile = false
    @State private var showSavedPhrases = false
    @State private var askAIPhrase: EnglishPhrase?
    @State private var accountActionError: String?
    
    var body: some View {
        if !sessionService.isAuthenticated {
            OnboardingView()
        } else {
        ZStack {
            // Background
            LumenColors.navyDark
                .ignoresSafeArea()
            
            // Content
            if viewModel.isLoading {
                // Loading state
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
        .sheet(item: $askAIPhrase) { phrase in
            AskAIView(
                phrase: phrase,
                onAsk: { question in
                    await viewModel.askAI(phrase: phrase.text, question: question)
                }
            )
        }
        .alert(LocalizedStrings.feedErrorTitle, isPresented: Binding(
            get: { accountActionError != nil },
            set: { isPresented in if !isPresented { accountActionError = nil } }
        )) {
            Button(LocalizedStrings.commonOk, role: .cancel) {}
        } message: {
            Text(accountActionError ?? "")
        }
        .onDisappear {
            audioService.stop()
        }
        .onAppear {
            viewModel.updateFavoriteSignals(from: favorites)
        }
        .onChange(of: favorites.count) { _, _ in
            viewModel.updateFavoriteSignals(from: favorites)
        }
        .onChange(of: viewModel.phrases.count) { _, count in
            // +1 tail page always exists at index == count.
            currentPage = min(currentPage, count)
            viewModel.prefetchBackgrounds(around: currentPage)
        }
        .onChange(of: currentPage) { _, newPage in
            viewModel.ensureMorePhrasesIfNeeded(currentIndex: newPage)
            viewModel.prefetchBackgrounds(around: newPage)
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
                            onPlayAudio: {
                                audioService.togglePlayback(for: phrase.id, text: phrase.text)
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
        favorites.contains {
            $0.text.caseInsensitiveCompare(phrase.text) == .orderedSame
        }
    }

    private func toggleFavorite(_ phrase: EnglishPhrase) {
        if let existing = favorites.first(where: { $0.text.caseInsensitiveCompare(phrase.text) == .orderedSame }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(
                FavoritePhrase(
                    text: phrase.text,
                    translation: phrase.translation,
                    category: phrase.category,
                    difficulty: phrase.difficulty.rawValue
                )
            )
        }

        do {
            try modelContext.save()
        } catch {
            accountActionError = error.localizedDescription
        }
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
        context.coordinator.updateControllers(with: pages)
        
        guard !context.coordinator.controllers.isEmpty else { return }
        let safePage = min(max(currentPage, 0), context.coordinator.controllers.count - 1)
        if safePage == context.coordinator.currentPage {
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
        
        init(_ parent: VerticalPageView) {
            self.parent = parent
            self.controllers = parent.pages.map { Self.makeHostingController(rootView: $0) }
            self.currentPage = parent.currentPage
        }
        
        func updateControllers(with pages: [Page]) {
            if controllers.count != pages.count {
                controllers = pages.map { Self.makeHostingController(rootView: $0) }
                return
            }
            
            for index in pages.indices {
                if let hosting = controllers[index] as? UIHostingController<Page> {
                    hosting.rootView = pages[index]
                    hosting.view.backgroundColor = .clear
                }
            }
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
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard
                completed,
                let visible = pageViewController.viewControllers?.first,
                let index = controllers.firstIndex(where: { $0 === visible })
            else { return }
            currentPage = index
            parent.currentPage = index
        }
    }
}

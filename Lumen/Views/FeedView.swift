import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var audioService = AudioService.shared
    @StateObject private var sessionService = SessionService.shared
    @State private var currentPage = 0
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showEditProfile = false
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
                    pages: viewModel.phrases.map { phrase in
                        PhraseCard(
                            phrase: phrase,
                            isSaved: viewModel.savedPhraseIDs.contains(phrase.id),
                            isAudioPlaying: audioService.currentlyPlayingPhraseID == phrase.id,
                            onPlayAudio: {
                                audioService.togglePlayback(for: phrase.id, text: phrase.text)
                            },
                            onAskAI: {
                                // TODO: Show AI feedback in a modal or sheet
                                Task {
                                    let feedback = await viewModel.getPhraseFeedback(phrase.text)
                                    print("AI Feedback: \(feedback)")
                                }
                            },
                            onSave: {
                                viewModel.toggleSavePhrase(phrase.id)
                            }
                        )
                    },
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

            VStack {
                HStack {
                    Spacer()
                    Menu {
                        Button(role: .none) {
                            showEditProfile = true
                        } label: {
                            Label(LocalizedStrings.feedEditProfile, systemImage: "slider.horizontal.3")
                        }

                        Button(role: .none) {
                            showLogoutConfirm = true
                        } label: {
                            Label(LocalizedStrings.accountLogout, systemImage: "rectangle.portrait.and.arrow.right")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label(LocalizedStrings.accountDelete, systemImage: "trash")
                        }
                    } label: {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 58)

                Spacer()
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(LocalizedStrings.accountLogoutConfirmTitle, isPresented: $showLogoutConfirm) {
            Button(LocalizedStrings.accountCancel, role: .cancel) {}
            Button(LocalizedStrings.accountLogout, role: .destructive) {
                Task {
                    await sessionService.logout()
                }
            }
        } message: {
            Text(LocalizedStrings.accountLogoutConfirmMessage)
        }
        .alert(LocalizedStrings.accountDeleteConfirmTitle, isPresented: $showDeleteConfirm) {
            Button(LocalizedStrings.accountCancel, role: .cancel) {}
            Button(LocalizedStrings.accountDelete, role: .destructive) {
                Task {
                    do {
                        try await sessionService.deleteAccount()
                    } catch {
                        accountActionError = error.localizedDescription
                    }
                }
            }
        } message: {
            Text(LocalizedStrings.accountDeleteConfirmMessage)
        }
        .alert(LocalizedStrings.feedErrorTitle, isPresented: Binding(
            get: { accountActionError != nil },
            set: { isPresented in if !isPresented { accountActionError = nil } }
        )) {
            Button(LocalizedStrings.commonOk, role: .cancel) {}
        } message: {
            Text(accountActionError ?? "")
        }
        .sheet(isPresented: $showEditProfile) {
            if let token = sessionService.accessToken {
                UserPreferencesView(accessToken: token)
            }
        }
        .onDisappear {
            audioService.stop()
        }
        .onChange(of: viewModel.phrases.count) { _, count in
            guard count > 0 else {
                currentPage = 0
                return
            }
            currentPage = min(currentPage, count - 1)
        }
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
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
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
            self.controllers = parent.pages.map { UIHostingController(rootView: $0) }
            self.currentPage = parent.currentPage
        }
        
        func updateControllers(with pages: [Page]) {
            if controllers.count != pages.count {
                controllers = pages.map { UIHostingController(rootView: $0) }
                return
            }
            
            for index in pages.indices {
                if let hosting = controllers[index] as? UIHostingController<Page> {
                    hosting.rootView = pages[index]
                }
            }
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

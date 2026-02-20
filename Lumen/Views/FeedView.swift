import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
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
                            onAskAI: {
                                // TODO: Show AI feedback in a modal or sheet
                                Task {
                                    let feedback = await viewModel.getPhraseFeedback(phrase.text)
                                    print("AI Feedback: \(feedback)")
                                }
                            },
                            onSave: { isSaved in
                                viewModel.toggleSavePhrase(phrase.id)
                            }
                        )
                    },
                    currentPage: .constant(0)
                )
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
        }
        .navigationBarBackButtonHidden(true)
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
        
        let direction: UIPageViewController.NavigationDirection =
            currentPage >= context.coordinator.currentPage ? .forward : .reverse
        
        uiViewController.setViewControllers(
            [context.coordinator.controllers[currentPage]],
            direction: direction,
            animated: true
        )
        
        context.coordinator.currentPage = currentPage
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

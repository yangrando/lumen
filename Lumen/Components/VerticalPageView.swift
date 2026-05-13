import SwiftUI
import UIKit

/// UIPageViewController vertical com suporte a páginas SwiftUI genéricas.
/// Gerencia adição incremental de páginas sem reconstruir controllers existentes.
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
                uiViewController.setViewControllers([visible], direction: .forward, animated: false)
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

    // MARK: - Coordinator

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
            guard let index = controllers.firstIndex(where: { $0 === viewController }),
                  index > 0 else { return nil }
            return controllers[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = controllers.firstIndex(where: { $0 === viewController }),
                  index + 1 < controllers.count else { return nil }
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
            guard completed,
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
            guard let pageViewController, let pendingPage else { return }
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

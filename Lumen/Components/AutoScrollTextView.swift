import SwiftUI
import UIKit

struct AutoScrollTextView: UIViewRepresentable {
    let tokens: [HighlightedWord]
    @Binding var isAutoScrolling: Bool
    let speedPointsPerSecond: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.backgroundColor = .clear

        let hosting = UIHostingController(rootView: makeRootView())
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        context.coordinator.hostingController = hosting
        context.coordinator.scrollView = scrollView

        scrollView.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        update(scrollView, context: context)
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        update(uiView, context: context)
    }

    private func update(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = makeRootView()
        context.coordinator.configure(
            scrollView: uiView,
            isAutoScrolling: isAutoScrolling,
            speedPointsPerSecond: speedPointsPerSecond
        )
    }

    private func makeRootView() -> AnyView {
        AnyView(
            HighlightedPhraseTextContent(tokens: tokens, onTapWord: nil)
                .padding(.top, 8)
                .padding(.horizontal, 4)
                .background(Color.clear)
        )
    }

    final class Coordinator {
        weak var scrollView: UIScrollView?
        var hostingController: UIHostingController<AnyView>?
        private var displayLink: CADisplayLink?
        private var speed: CGFloat = 24
        private var autoScrolling = false

        func configure(scrollView: UIScrollView, isAutoScrolling: Bool, speedPointsPerSecond: CGFloat) {
            self.scrollView = scrollView
            self.speed = speedPointsPerSecond
            if isAutoScrolling != autoScrolling {
                autoScrolling = isAutoScrolling
                if autoScrolling {
                    start()
                } else {
                    stop()
                    scrollView.setContentOffset(.zero, animated: false)
                }
            } else if autoScrolling {
                start()
            } else {
                stop()
                scrollView.setContentOffset(.zero, animated: false)
            }
        }

        @objc private func tick() {
            guard let scrollView else { return }
            let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
            guard maxOffset > 0 else { return }

            var nextY = scrollView.contentOffset.y + (speed / 60.0)
            if nextY >= maxOffset {
                nextY = maxOffset
                stop()
                autoScrolling = false
            }
            scrollView.setContentOffset(CGPoint(x: 0, y: nextY), animated: false)
        }

        private func start() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func stop() {
            displayLink?.invalidate()
            displayLink = nil
        }

        deinit {
            stop()
        }
    }
}

import SwiftUI
import UIKit

struct AutoScrollTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    let alignment: NSTextAlignment
    @Binding var isAutoScrolling: Bool
    let speedPointsPerSecond: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = true
        view.isOpaque = false
        view.backgroundColor = .clear
        view.layer.backgroundColor = UIColor.clear.cgColor
        view.tintColor = .clear
        view.textContainer.lineFragmentPadding = 0
        view.textContainerInset = .init(top: 8, left: 4, bottom: 8, right: 4)
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = true
        update(view, context: context)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        update(uiView, context: context)
    }

    private func update(_ uiView: UITextView, context: Context) {
        uiView.backgroundColor = .clear
        uiView.layer.backgroundColor = UIColor.clear.cgColor
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineSpacing = 3
        uiView.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .backgroundColor: UIColor.clear,
                .paragraphStyle: paragraph
            ]
        )
        context.coordinator.configure(
            textView: uiView,
            isAutoScrolling: isAutoScrolling,
            speedPointsPerSecond: speedPointsPerSecond
        )
    }

    final class Coordinator {
        private weak var textView: UITextView?
        private var displayLink: CADisplayLink?
        private var speed: CGFloat = 24
        private var autoScrolling = false

        func configure(textView: UITextView, isAutoScrolling: Bool, speedPointsPerSecond: CGFloat) {
            self.textView = textView
            self.speed = speedPointsPerSecond
            if isAutoScrolling != autoScrolling {
                autoScrolling = isAutoScrolling
                autoScrolling ? start() : stop()
            } else if autoScrolling {
                start()
            }
        }

        @objc private func tick() {
            guard let textView else { return }
            let maxOffset = max(0, textView.contentSize.height - textView.bounds.height)
            guard maxOffset > 0 else { return }

            var nextY = textView.contentOffset.y + (speed / 60.0)
            if nextY >= maxOffset {
                nextY = maxOffset
                stop()
                autoScrolling = false
            }
            textView.setContentOffset(CGPoint(x: 0, y: nextY), animated: false)
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

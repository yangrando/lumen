import SwiftUI

struct HighlightedPhraseTextContent: View {
    let tokens: [HighlightedWord]
    let onTapWord: ((HighlightedWord) -> Void)?

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .center) {
            flowContent
        }
        .frame(maxWidth: .infinity)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { availableWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        availableWidth = newWidth
                    }
            }
        )
    }

    private var flowContent: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(tokens) { token in
                tokenView(token)
                    .padding(.trailing, 6)
                    .padding(.bottom, 10)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > availableWidth {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        if token.id == tokens.last?.id {
                            width = 0
                        } else {
                            width -= dimension.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { dimension in
                        let result = height
                        if token.id == tokens.last?.id {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }

    private func tokenView(_ token: HighlightedWord) -> some View {
        Text(token.rawToken.uppercased())
            .font(LumenFont.grotesk(20, weight: .bold))
            .tracking(-0.4)
            .foregroundStyle(token.isHighlighted ? LumenColors.accent : LumenColors.ink50)
            .padding(.horizontal, token.isHighlighted ? 4 : 0)
            .padding(.vertical, token.isHighlighted ? 2 : 0)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(token.isHighlighted ? LumenColors.accentSoft : .clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard token.isHighlighted else { return }
                onTapWord?(token)
            }
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: token.isHighlighted)
    }
}

struct HighlightedPhraseTextView: View {
    let tokens: [HighlightedWord]
    let onTapWord: (HighlightedWord) -> Void

    var body: some View {
        HighlightedPhraseTextContent(tokens: tokens, onTapWord: onTapWord)
    }
}

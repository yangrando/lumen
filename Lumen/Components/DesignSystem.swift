import SwiftUI

// MARK: - LumenButton
// Sizes: sm (h36), md (h48), lg (h56)
// Kinds: primary, secondary, ghost, text, danger

enum LumenButtonKind { case primary, secondary, ghost, text, danger }
enum LumenButtonSize { case sm, md, lg }

struct LumenButton: View {
    var kind: LumenButtonKind = .primary
    var size: LumenButtonSize = .md
    var isDisabled: Bool = false
    var isFullWidth: Bool = false
    var label: String
    var icon: (any View)? = nil
    var action: () -> Void = {}

    private var height: CGFloat  { switch size { case .sm: 36; case .md: 48; case .lg: 56 } }
    private var fontSize: CGFloat { switch size { case .sm: 13; case .md: 14; case .lg: 16 } }
    private var hPad: CGFloat    { switch size { case .sm: 14; case .md: 20; case .lg: 26 } }

    private var bgColor: Color {
        switch kind {
        case .primary:   return LumenColors.accent
        case .secondary: return LumenColors.ink800
        case .ghost, .text, .danger: return .clear
        }
    }

    private var fgColor: Color {
        switch kind {
        case .primary:   return LumenColors.ink900
        case .secondary: return LumenColors.ink100
        case .ghost:     return LumenColors.ink100
        case .text:      return LumenColors.ink300
        case .danger:    return Color(hex: "#FF6E6E")
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary:              return .clear
        case .secondary, .ghost:    return LumenColors.ink700
        case .text:                 return .clear
        case .danger:               return Color(hex: "#FF6E6E").opacity(0.2)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    AnyView(icon)
                }
                Text(label)
                    .font(LumenFont.grotesk(fontSize, weight: .medium))
                    .kerning(fontSize * -0.01)
            }
            .foregroundColor(fgColor)
            .frame(height: height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, hPad)
            .background(bgColor)
            .overlay(
                Capsule().stroke(borderColor, lineWidth: 1)
            )
            .clipShape(Capsule())
            .opacity(isDisabled ? 0.4 : 1)
        }
        .disabled(isDisabled)
    }
}

// MARK: - LumenInput

struct LumenInput: View {
    var label: String? = nil
    var placeholder: String = ""
    @Binding var text: String
    var hint: String? = nil
    var leadingIcon: (any View)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                Text(label)
                    .font(LumenFont.mono(10, weight: .medium))
                    .kerning(10 * 0.14)
                    .textCase(.uppercase)
                    .foregroundColor(LumenColors.ink400)
            }
            HStack(spacing: 12) {
                if let icon = leadingIcon {
                    AnyView(icon)
                        .foregroundColor(LumenColors.ink400)
                }
                TextField(placeholder, text: $text)
                    .font(LumenFont.grotesk(15))
                    .kerning(15 * -0.01)
                    .foregroundColor(LumenColors.ink100)
                    .tint(LumenColors.accent)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(LumenColors.ink850)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LumenColors.ink600, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if let hint {
                Text(hint)
                    .font(LumenFont.grotesk(12))
                    .foregroundColor(LumenColors.ink400)
            }
        }
    }
}

// MARK: - LumenChip (interest selector)

struct LumenChip: View {
    var label: String
    var icon: (any View)? = nil
    var isActive: Bool = false
    var size: LumenButtonSize = .md

    private var height: CGFloat   { size == .lg ? 52 : 40 }
    private var fontSize: CGFloat { size == .lg ? 15 : 13 }
    private var hPad: CGFloat     { size == .lg ? 20 : 16 }

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                AnyView(icon)
            }
            Text(label)
                .font(LumenFont.grotesk(fontSize, weight: isActive ? .medium : .regular))
                .kerning(fontSize * -0.01)
        }
        .foregroundColor(isActive ? LumenColors.ink900 : LumenColors.ink100)
        .frame(height: height)
        .padding(.horizontal, hPad)
        .background(isActive ? LumenColors.accent : LumenColors.ink800)
        .overlay(
            Capsule().stroke(isActive ? LumenColors.accent : LumenColors.ink700, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - LumenActionRail (TikTok-style vertical, floating)

struct LumenActionRailItem {
    let icon: AnyView
    let label: String
    var isAccent: Bool = false
    var action: () -> Void = {}
}

struct LumenActionRail: View {
    let items: [LumenActionRailItem]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button(action: item.action) {
                    VStack(spacing: 5) {
                        item.icon
                            .foregroundColor(item.isAccent ? LumenColors.ink900 : LumenColors.ink100)
                            .frame(width: 48, height: 48)
                            .background(
                                item.isAccent
                                    ? LumenColors.accent
                                    : Color.white.opacity(0.06)
                            )
                            .overlay(
                                Circle().stroke(
                                    item.isAccent ? Color.clear : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                            )
                            .clipShape(Circle())
                            .background(.ultraThinMaterial.opacity(item.isAccent ? 0 : 1), in: Circle())

                        Text(item.label)
                            .font(LumenFont.mono(9, weight: .regular))
                            .kerning(9 * 0.12)
                            .textCase(.uppercase)
                            .foregroundColor(LumenColors.ink300)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - LumenProgressRing

struct LumenProgressRing: View {
    var percent: Double    // 0–100
    var size: CGFloat = 120

    private var radius: CGFloat { size / 2 - 6 }
    private var circumference: CGFloat { 2 * .pi * radius }
    private var dashOffset: CGFloat { circumference - (percent / 100) * circumference }

    var body: some View {
        ZStack {
            // track
            Circle()
                .stroke(LumenColors.ink700, lineWidth: 4)
            // progress
            Circle()
                .trim(from: 0, to: percent / 100)
                .stroke(LumenColors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            // label
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("\(Int(percent))")
                    .font(LumenFont.grotesk(28))
                    .foregroundColor(LumenColors.ink50)
                Text("%")
                    .font(LumenFont.grotesk(14))
                    .foregroundColor(LumenColors.ink400)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - LumenWaveform

struct LumenWaveform: View {
    var bars: Int = 42
    var width: CGFloat = 280
    var height: CGFloat = 56
    var activeFraction: Double = 0.55
    var activeColor: Color = LumenColors.accent
    var inactiveColor: Color = Color.white.opacity(0.2)

    private var barHeights: [CGFloat] {
        var result = [CGFloat]()
        var seed: Int = 42
        for i in 0..<bars {
            seed = (seed * 9301 + 49297) % 233280
            let v = Double(seed) / 233280.0
            let envelope = sin(Double(i) / Double(bars) * .pi)
            result.append(CGFloat(0.25 + v * 0.6 * envelope + 0.2))
        }
        return result
    }

    var body: some View {
        Canvas { ctx, size in
            let bw = size.width / CGFloat(bars * 2 - 1)
            let heights = barHeights
            for (i, h) in heights.enumerated() {
                let bh = h * size.height * 0.85
                let x = CGFloat(i) * (bw * 2)
                let y = (size.height - bh) / 2
                let rect = CGRect(x: x, y: y, width: bw, height: bh)
                let path = Path(roundedRect: rect, cornerRadius: bw / 2)
                let isActive = Double(i) < Double(bars) * activeFraction
                ctx.fill(path, with: .color(isActive ? activeColor : inactiveColor))
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - LumenPhraseCard (resting state)

struct LumenPhraseCard: View {
    var topic: String = "TRAVEL"
    var level: String = "B2"
    var duration: String = "08 SEC"
    var phraseText: AttributedString
    var ipaText: String = ""
    var cardIndex: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tags row
            HStack(spacing: 6) {
                LumenTag(topic, color: LumenColors.accent)
                LumenTag("\(level) · CONDITIONAL")
                LumenTag(duration)
            }
            .padding(.bottom, 22)

            // Phrase
            Text(phraseText)
                .font(LumenFont.grotesk(28))
                .kerning(28 * -0.02)
                .foregroundColor(LumenColors.ink50)
                .lineSpacing(8)

            Divider()
                .background(LumenColors.ink700)
                .padding(.vertical, 16)

            // IPA + card index
            HStack {
                Text(ipaText)
                    .font(LumenFont.mono(11))
                    .foregroundColor(LumenColors.ink400)
                Spacer()
                Text(cardIndex)
                    .font(LumenFont.mono(10, weight: .medium))
                    .kerning(10 * 0.14)
                    .foregroundColor(LumenColors.ink400)
            }
        }
        .padding(28)
        .background(LumenColors.ink900)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LumenColors.ink700, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - LumenTag (metadata pill)

struct LumenTag: View {
    let text: String
    var color: Color = LumenColors.ink300

    init(_ text: String, color: Color = LumenColors.ink300) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(LumenFont.mono(11, weight: .medium))
            .kerning(11 * 0.14)
            .textCase(.uppercase)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(
                Capsule().stroke(color.opacity(0.5), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Design System") {
    ScrollView {
        VStack(alignment: .leading, spacing: 32) {

            // Buttons
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    LumenButton(kind: .primary, size: .lg, label: "Start practicing")
                    LumenButton(kind: .secondary, size: .lg, label: "Skip for now")
                }
                HStack(spacing: 10) {
                    LumenButton(kind: .primary, label: "Continue")
                    LumenButton(kind: .secondary, label: "Back")
                    LumenButton(kind: .ghost, label: "Cancel")
                }
                HStack(spacing: 10) {
                    LumenButton(kind: .primary, size: .sm, label: "Follow")
                    LumenButton(kind: .secondary, size: .sm, label: "Saved")
                    LumenButton(kind: .danger, size: .sm, label: "Remove")
                    LumenButton(kind: .primary, size: .sm, isDisabled: true, label: "Next")
                }
            }

            // Chips
            HStack(spacing: 8) {
                LumenChip(label: "Travel", isActive: true, size: .lg)
                LumenChip(label: "Business", isActive: true, size: .lg)
                LumenChip(label: "Movies", size: .lg)
                LumenChip(label: "Tech", size: .lg)
            }

            // Progress + Waveform
            HStack(spacing: 24) {
                LumenProgressRing(percent: 72, size: 120)
                LumenWaveform()
            }

            // Phrase card
            LumenPhraseCard(
                phraseText: try! AttributedString(markdown: "\"If I **had known** about the delay, I would have booked a later flight.\""),
                ipaText: "/ ɪf aɪ həd noʊn əˈbaʊt ðə dɪˈleɪ /",
                cardIndex: "03 / 24"
            )
        }
        .padding(24)
    }
    .background(LumenColors.ink900)
    .preferredColorScheme(.dark)
}

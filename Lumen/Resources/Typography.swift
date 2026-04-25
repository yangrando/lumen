import SwiftUI

// MARK: - Lumen Design System · Type Scale
// Primary: Space Grotesk (display + UI)
// Mono:    Geist Mono (metadata, IPA, tags)
// Accent:  Instrument Serif Italic (editorial)

enum LumenFont {
    // MARK: - Family names (matching registered font PostScript names)
    static let grotesk   = "SpaceGrotesk"
    static let mono      = "GeistMono"
    static let serif     = "InstrumentSerif"

    // MARK: - Space Grotesk helpers
    static func grotesk(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let postscript: String
        switch weight {
        case .light:      postscript = "SpaceGrotesk-Light"
        case .medium:     postscript = "SpaceGrotesk-Medium"
        case .semibold:   postscript = "SpaceGrotesk-SemiBold"
        case .bold:       postscript = "SpaceGrotesk-Bold"
        default:          postscript = "SpaceGrotesk-Regular"
        }
        return Font.custom(postscript, size: size)
    }

    // MARK: - Geist Mono helpers
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let postscript = (weight == .medium) ? "GeistMono-Medium" : "GeistMono-Regular"
        return Font.custom(postscript, size: size)
    }

    // MARK: - Instrument Serif italic
    static func serifItalic(_ size: CGFloat) -> Font {
        Font.custom("InstrumentSerif-Italic", size: size)
    }
}

// MARK: - Named text styles matching design spec
extension Font {
    // Display / XL — SG 300 · 72 / -4%
    static let lumenDisplayXL = LumenFont.grotesk(72, weight: .light)
    // Display / L  — SG 400 · 56 / -3%
    static let lumenDisplayL  = LumenFont.grotesk(56)
    // Title / H1   — SG 500 · 34 / -2%
    static let lumenH1        = LumenFont.grotesk(34, weight: .medium)
    // Title / H2   — SG 500 · 24 / -1%
    static let lumenH2        = LumenFont.grotesk(24, weight: .medium)
    // Sentence     — SG 400 · 28 / -2%
    static let lumenSentence  = LumenFont.grotesk(28)
    // Body         — SG 400 · 16
    static let lumenBody      = LumenFont.grotesk(16)
    // Caption      — SG 400 · 13
    static let lumenCaption   = LumenFont.grotesk(13)
    // Mono / Tag   — GM 500 · 11
    static let lumenTag       = LumenFont.mono(11, weight: .medium)
    // Mono / IPA   — GM 400 · 18
    static let lumenIPA       = LumenFont.mono(18)
    // Serif accent — Instrument Serif Italic · 48
    static let lumenSerifAccent = LumenFont.serifItalic(48)
}

// MARK: - Tracking (letter-spacing) constants
extension View {
    func lumenTracking(_ em: CGFloat, size: CGFloat) -> some View {
        self.tracking(em * size)
    }
}

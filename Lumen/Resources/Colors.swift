import SwiftUI

// MARK: - Lumen Design System · Photon Palette (Variation A)
// Dark-first. Grafite frio + lima neon accent.

struct LumenColors {

    // MARK: - Ink scale (dark surface → light text)
    static let ink900 = Color(hex: "#0A0B0D")  // App bg
    static let ink850 = Color(hex: "#0F1114")  // Surface
    static let ink800 = Color(hex: "#14161A")  // Card
    static let ink700 = Color(hex: "#1C1F24")  // Divider
    static let ink600 = Color(hex: "#272B32")  // Border
    static let ink500 = Color(hex: "#3A3F48")  // Disabled
    static let ink400 = Color(hex: "#5A6270")  // Meta
    static let ink300 = Color(hex: "#8A93A3")  // Secondary
    static let ink200 = Color(hex: "#B8BFCB")  // Placeholder
    static let ink100 = Color(hex: "#E4E7ED")  // Text
    static let ink50  = Color(hex: "#F3F4F7")  // High emphasis

    // MARK: - Photon accent (lime neon)
    static let accent        = Color(hex: "#C6FF4D")
    static let accentSoft    = Color(hex: "#C6FF4D").opacity(0.14)
    static let accentGlow    = Color(hex: "#C6FF4D").opacity(0.35)

    // MARK: - Semantic
    static let good = Color(hex: "#7CE3B5")
    static let warn = Color(hex: "#FFB156")
    static let bad  = Color(hex: "#FF6E6E")
    static let info = Color(hex: "#8BB8FF")

    // MARK: - Legacy aliases (backward-compat with existing code)
    static let navyDark         = ink900
    static let navyLight        = ink800
    static let gradientStart    = accent
    static let gradientEnd      = Color(hex: "#A8FF00")
    static let textPrimary      = ink50
    static let textSecondary    = ink300
    static let textTertiary     = ink400
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [LumenColors.accent, Color(hex: "#A8FF00")]),
        startPoint: .leading,
        endPoint: .trailing
    )

    static let primaryGradientDiagonal = LinearGradient(
        gradient: Gradient(colors: [LumenColors.accent, Color(hex: "#A8FF00")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color(hex:) initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

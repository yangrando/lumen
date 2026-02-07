import SwiftUI

// MARK: - Lumen Color Palette
struct LumenColors {
    // MARK: - Navy (Fundo)
    static let navyDark = Color(red: 0.06, green: 0.09, blue: 0.17)      // #0f172a
    static let navyLight = Color(red: 0.12, green: 0.16, blue: 0.23)     // #1e293b
    
    // MARK: - Gradiente Principal
    static let gradientStart = Color(red: 0.02, green: 0.71, blue: 0.84)  // #06b6d4 (Ciano)
    static let gradientEnd = Color(red: 0.49, green: 0.24, blue: 0.93)    // #7c3aed (Roxo)
    
    // MARK: - Texto
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.6, green: 0.65, blue: 0.7)    // Cinza claro
    static let textTertiary = Color(red: 0.5, green: 0.5, blue: 0.55)     // Cinza mais escuro
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [
            LumenColors.gradientStart,
            LumenColors.gradientEnd
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let primaryGradientDiagonal = LinearGradient(
        gradient: Gradient(colors: [
            LumenColors.gradientStart,
            LumenColors.gradientEnd
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

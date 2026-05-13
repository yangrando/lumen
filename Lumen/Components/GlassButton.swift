import SwiftUI

// MARK: - Glass Button Component
struct GlassButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(LumenFont.grotesk(18, weight: .semibold))
                Text(title)
                    .font(LumenFont.grotesk(16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(LumenColors.ink50)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Gradient Button Component
struct GradientButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(LumenFont.grotesk(18, weight: .semibold))
                Text(title)
                    .font(LumenFont.grotesk(16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(LumenColors.ink900)
            .background(LinearGradient.primaryGradient)
            .clipShape(Capsule())
            .shadow(color: LumenColors.gradientEnd.opacity(0.3), radius: 10, y: 5)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassButton(title: "Continue with Apple", icon: "apple.logo", action: { print("Apple tapped") })
        GradientButton(title: "Sign up with Email", icon: "envelope.fill", action: { print("Email tapped") })
    }
    .padding()
    .background(LumenColors.navyDark)
    .ignoresSafeArea()
}

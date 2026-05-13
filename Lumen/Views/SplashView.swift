import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.82
    @State private var logoOpacity = 0.0
    @State private var glowOpacity = 0.0

    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            Circle()
                .fill(LinearGradient.primaryGradientDiagonal)
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .opacity(glowOpacity)

            VStack(spacing: 20) {
                LumenMark(size: 96, color: LumenColors.accent, glowEnabled: true)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                LumenWordmark(size: 38, color: LumenColors.ink50, accent: LumenColors.accent)
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                logoScale = 1.0
                logoOpacity = 1.0
                glowOpacity = 0.24
            }
        }
    }
}

#Preview {
    SplashView()
}

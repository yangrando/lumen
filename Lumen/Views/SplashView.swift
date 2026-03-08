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

            VStack(spacing: 14) {
                Image("LumenLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: LumenColors.gradientEnd.opacity(0.38), radius: 18, y: 8)

                Text("Lumen")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white.opacity(logoOpacity))
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

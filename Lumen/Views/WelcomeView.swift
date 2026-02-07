import SwiftUI

struct WelcomeView: View {
    
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Fundo escuro
            LumenColors.navyDark
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "flare.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(LinearGradient.primaryGradientDiagonal)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text("Lumen")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 40)
                
                // Título
                VStack(spacing: 12) {
                    (
                        Text("Learn English by reading about ")
                            .foregroundStyle(.white)
                        +
                        Text("what you love.")
                            .foregroundStyle(LinearGradient.primaryGradient)
                    )
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    
                    Text("Personalized feed with real-time AI feedback.")
                        .font(.system(size: 16))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Botões
                VStack(spacing: 12) {
                    GlassButton(
                        title: "Continue with Apple",
                        icon: "apple.logo",
                        action: onContinue
                    )
                    
                    GlassButton(
                        title: "Continue with Google",
                        icon: "globe",
                        action: onContinue
                    )
                    
                    GradientButton(
                        title: "Sign up with Email",
                        icon: "envelope.fill",
                        action: onContinue
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

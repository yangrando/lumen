import SwiftUI

struct OnboardingCompletionView: View {
    var body: some View {
        ZStack {
            // Background
            LumenColors.navyDark
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Success icon with animation
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(LinearGradient.primaryGradient)
                    
                    VStack(spacing: 12) {
                        Text(LocalizedStrings.completionTitle)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text(LocalizedStrings.completionDescription)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(LumenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Start learning button
                NavigationLink(destination: ContentView()) {
                    Text(LocalizedStrings.completionStartButton)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(.white)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingCompletionView()
}

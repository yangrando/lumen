import SwiftUI

struct NativeLanguageSelectionView: View {
    let selectedLanguage: String
    let onContinue: (String) -> Void

    @State private var currentLanguage: String

    init(selectedLanguage: String, onContinue: @escaping (String) -> Void) {
        self.selectedLanguage = selectedLanguage
        self.onContinue = onContinue
        _currentLanguage = State(initialValue: selectedLanguage)
    }

    private let languages: [String] = [
        "Portuguese (Brazil)",
        "Spanish",
        "French",
        "German",
        "Italian",
        "Russian",
        "Japanese",
        "Korean",
        "Chinese (Simplified)"
    ]

    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("What's your native language?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                Text("We'll use this language for phrase translations.")
                    .font(.system(size: 15))
                    .foregroundStyle(LumenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 10) {
                    ForEach(languages, id: \.self) { language in
                        Button {
                            currentLanguage = language
                        } label: {
                            HStack {
                                Text(language)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                if currentLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(LinearGradient.primaryGradient)
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color.white.opacity(currentLanguage == language ? 0.18 : 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                GradientButton(
                    title: LocalizedStrings.levelContinueButton,
                    icon: "arrow.right",
                    action: { onContinue(currentLanguage) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
        }
    }
}

#Preview {
    NativeLanguageSelectionView(selectedLanguage: "Portuguese (Brazil)", onContinue: { _ in })
}

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
        "English",
        "French",
        "German",
        "Italian",
        "Russian",
        "Japanese",
        "Korean",
        "Chinese (Simplified)"
    ]

    private var localizedLanguageLabels: [String: String] {
        [
            "Portuguese (Brazil)": LocalizedStrings.nativeLanguageOptionPortugueseBrazil,
            "Spanish": LocalizedStrings.nativeLanguageOptionSpanish,
            "English": LocalizedStrings.nativeLanguageOptionEnglish,
            "French": LocalizedStrings.nativeLanguageOptionFrench,
            "German": LocalizedStrings.nativeLanguageOptionGerman,
            "Italian": LocalizedStrings.nativeLanguageOptionItalian,
            "Russian": LocalizedStrings.nativeLanguageOptionRussian,
            "Japanese": LocalizedStrings.nativeLanguageOptionJapanese,
            "Korean": LocalizedStrings.nativeLanguageOptionKorean,
            "Chinese (Simplified)": LocalizedStrings.nativeLanguageOptionChineseSimplified
        ]
    }

    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(LocalizedStrings.nativeLanguageTitle)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)

                Text(LocalizedStrings.nativeLanguageDescription)
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
                                Text(localizedLanguageLabels[language] ?? language)
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

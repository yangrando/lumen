import SwiftUI

struct NativeLanguageSelectionView: View {
    let selectedLanguage: String
    let onBack: () -> Void
    let onContinue: (String) -> Void

    @State private var currentLanguage: String?

    init(selectedLanguage: String, onBack: @escaping () -> Void, onContinue: @escaping (String) -> Void) {
        self.selectedLanguage = selectedLanguage
        self.onBack = onBack
        self.onContinue = onContinue
        _currentLanguage = State(initialValue: selectedLanguage.isEmpty ? nil : selectedLanguage)
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
            onboardingBackground

            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 18) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(LumenFont.grotesk(18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }

                    Text(LocalizedStrings.nativeLanguageTitle)
                        .font(LumenFont.grotesk(24, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    Text(LocalizedStrings.nativeLanguageDescription)
                        .font(LumenFont.grotesk(15))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                VStack(spacing: 10) {
                    ForEach(languages, id: \.self) { language in
                        Button {
                            currentLanguage = language
                        } label: {
                            HStack {
                                Text(localizedLanguageLabels[language] ?? language)
                                    .font(LumenFont.grotesk(16, weight: .semibold))
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
                .padding(.horizontal, 24)

                Spacer()
            }

            VStack {
                Spacer()
                footer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            LumenButton(
                kind: .primary, size: .lg,
                isDisabled: currentLanguage == nil,
                isFullWidth: true,
                label: LocalizedStrings.levelContinueButton
            ) {
                if let currentLanguage { onContinue(currentLanguage) }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
        .padding(.bottom, 15)
        .background(
            LinearGradient(
                colors: [
                    LumenColors.navyDark.opacity(0.0),
                    LumenColors.navyDark.opacity(0.96),
                    LumenColors.navyDark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var onboardingBackground: some View {
        ZStack {
            LumenColors.ink900
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    LumenColors.gradientEnd.opacity(0.18),
                    .clear
                ],
                center: .top,
                startRadius: 40,
                endRadius: 340
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    NativeLanguageSelectionView(selectedLanguage: "Portuguese (Brazil)", onBack: {}, onContinue: { _ in })
}

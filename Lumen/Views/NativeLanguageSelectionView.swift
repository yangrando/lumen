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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }

                    Text(LocalizedStrings.nativeLanguageTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    Text(LocalizedStrings.nativeLanguageDescription)
                        .font(.system(size: 15))
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
            Button {
                if let currentLanguage {
                    onContinue(currentLanguage)
                }
            } label: {
                Text(LocalizedStrings.levelContinueButton)
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .foregroundStyle(.white)
                    .background(
                        currentLanguage == nil
                        ? AnyShapeStyle(Color.white.opacity(0.10))
                        : AnyShapeStyle(LinearGradient.primaryGradient)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(currentLanguage == nil)
            .opacity(currentLanguage == nil ? 0.55 : 1.0)
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
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.16),
                    Color(red: 0.05, green: 0.10, blue: 0.20),
                    Color(red: 0.04, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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

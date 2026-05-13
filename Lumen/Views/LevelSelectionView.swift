import SwiftUI

struct LevelSelectionView: View {
    @State private var selectedLevel: EnglishLevel? = nil

    let onBack: () -> Void
    let onContinue: (EnglishLevel) -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(EnglishLevel.allCases) { level in
                            LevelCard(
                                level: level,
                                isSelected: selectedLevel == level,
                                action: { selectedLevel = level }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    .padding(.bottom, 140)
                }
            }

            VStack {
                Spacer()
                footer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var background: some View {
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(LumenFont.grotesk(18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.levelSelectionTitle)
                    .font(LumenFont.grotesk(24, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.95)

                Text(LocalizedStrings.levelSelectionDescription)
                    .font(LumenFont.grotesk(15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            LumenButton(
                kind: .primary, size: .lg,
                isDisabled: selectedLevel == nil,
                isFullWidth: true,
                label: LocalizedStrings.levelContinueButton
            ) {
                if let selectedLevel { onContinue(selectedLevel) }
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
}

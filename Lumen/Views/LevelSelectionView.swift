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

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Choose your English level")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.95)

                Text("We will adapt sentence length, vocabulary load, and grammar complexity to your current stage.")
                    .font(.system(size: 15, weight: .medium))
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
            Button {
                if let selectedLevel {
                    onContinue(selectedLevel)
                }
            } label: {
                Text(LocalizedStrings.levelContinueButton)
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .foregroundStyle(.white)
                    .background(selectedLevel == nil ? AnyShapeStyle(Color.white.opacity(0.10)) : AnyShapeStyle(LinearGradient.primaryGradient))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selectedLevel == nil)
            .opacity(selectedLevel == nil ? 0.55 : 1.0)
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

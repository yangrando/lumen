import SwiftUI

struct SubtopicsView: View {
    let interests: [UserInterest]
    let onBack: () -> Void
    let onContinue: ([LearningSubtopic]) -> Void

    @State private var selectedSubtopics: Set<LearningSubtopic> = []

    private var availableSubtopics: [LearningSubtopic] {
        LearningSubtopic.options(for: Set(interests))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            onboardingBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    ChipSelectionGrid(
                        items: availableSubtopics,
                        selectedItems: selectedSubtopics,
                        title: \.displayTitle,
                        onToggle: { item in
                            if selectedSubtopics.contains(item) {
                                selectedSubtopics.remove(item)
                            } else {
                                selectedSubtopics.insert(item)
                            }
                        }
                    )

                    Color.clear
                        .frame(height: 130)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)
            }

            bottomAction
        }
        .toolbar(.hidden, for: .navigationBar)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }

            Text(LocalizedStrings.subtopicsTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.subtopicsDescription)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bottomAction: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(spacing: 12) {
                Button(LocalizedStrings.subtopicsSkipButton) {
                    onContinue([])
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)

                Button {
                    onContinue(selectedSubtopics.sorted { $0.displayTitle < $1.displayTitle })
                } label: {
                    Text(LocalizedStrings.subtopicsContinueButton)
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .foregroundStyle(.white)
                        .background(AnyShapeStyle(LinearGradient.primaryGradient))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
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
}


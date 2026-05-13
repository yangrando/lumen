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
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(LumenFont.grotesk(18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }

            Text(LocalizedStrings.subtopicsTitle)
                .font(LumenFont.grotesk(24, weight: .bold))
                .foregroundStyle(.white)

            Text(LocalizedStrings.subtopicsDescription)
                .font(LumenFont.grotesk(16, weight: .medium))
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
                LumenButton(kind: .text, isFullWidth: true, label: LocalizedStrings.subtopicsSkipButton) {
                    onContinue([])
                }

                LumenButton(kind: .primary, size: .lg, isFullWidth: true, label: LocalizedStrings.subtopicsContinueButton) {
                    onContinue(selectedSubtopics.sorted { $0.displayTitle < $1.displayTitle })
                }
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


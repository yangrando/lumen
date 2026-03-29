import SwiftUI

struct ObjectivesView: View {
    @State private var selectedObjectives: Set<LearningObjective> = []

    let onBack: () -> Void
    let onContinue: ([LearningObjective]) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            onboardingBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    VStack(spacing: 14) {
                        ForEach(orderedObjectives) { objective in
                            ObjectiveCard(
                                objective: objective,
                                isSelected: selectedObjectives.contains(objective),
                                action: {
                                    if selectedObjectives.contains(objective) {
                                        selectedObjectives.remove(objective)
                                    } else {
                                        selectedObjectives.insert(objective)
                                    }
                                }
                            )
                        }
                    }

                    Color.clear
                        .frame(height: 120)
                }
                .padding(.horizontal, 16)
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

            Text(LocalizedStrings.objectivesPrimaryTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Text(LocalizedStrings.objectivesPrimaryDescription)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(spacing: 0) {
                Button(action: {
                    let selectedArray = Array(selectedObjectives).sorted { $0.rawValue < $1.rawValue }
                    onContinue(selectedArray)
                }) {
                    Text(LocalizedStrings.interestsContinueButton)
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .foregroundStyle(.white)
                        .background(
                            selectedObjectives.isEmpty
                            ? AnyShapeStyle(Color.white.opacity(0.10))
                            : AnyShapeStyle(LinearGradient.primaryGradient)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(selectedObjectives.isEmpty)
                .opacity(selectedObjectives.isEmpty ? 0.55 : 1)
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

    private var orderedObjectives: [LearningObjective] {
        [
            .businessCommunication,
            .travelConfidence,
            .understandMovies,
            .expandVocabulary,
            .passExams,
            .improveSpeaking,
            .dailyConversation,
            .improveAccent,
            .readingComprehension,
            .writingSkills
        ]
    }
}

#Preview {
    ObjectivesView(onBack: {}, onContinue: { _ in })
}

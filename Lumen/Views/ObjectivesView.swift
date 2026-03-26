import SwiftUI

struct ObjectivesView: View {
    @State private var selectedObjectives: Set<LearningObjective> = []

    let onBack: () -> Void
    let onContinue: ([LearningObjective]) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            LumenColors.navyDark
                .ignoresSafeArea()

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

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
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

            VStack(spacing: 14) {
                Button(action: {
                    let selectedArray = Array(selectedObjectives).sorted { $0.rawValue < $1.rawValue }
                    onContinue(selectedArray)
                }) {
                    Text(LocalizedStrings.interestsContinueButton)
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(.white)
                        .background(
                            selectedObjectives.isEmpty
                            ? LinearGradient(
                                colors: [LumenColors.navyLight, LumenColors.navyLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient.primaryGradient
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(selectedObjectives.isEmpty)
                .opacity(selectedObjectives.isEmpty ? 0.55 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 22)
            .background(LumenColors.navyDark)
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

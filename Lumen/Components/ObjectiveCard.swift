import SwiftUI

struct ObjectiveCard: View {
    let objective: LearningObjective
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.14 : 0.06))
                        .frame(width: 44, height: 44)

                    Image(systemName: objective.icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.82))
                }

                Text(objective.localizedTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.96))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                            ? LumenColors.gradientStart.opacity(0.95)
                            : Color(red: 0.28, green: 0.34, blue: 0.44),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(LumenColors.gradientStart.opacity(0.92))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundStyle)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected
                        ? LinearGradient.primaryGradient
                        : LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: isSelected ? LumenColors.gradientEnd.opacity(0.12) : Color.black.opacity(0.10),
                radius: 14,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
    }

    private var backgroundStyle: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.20, blue: 0.36),
                        Color(red: 0.18, green: 0.24, blue: 0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color(red: 0.12, green: 0.16, blue: 0.23))
    }
}

private extension LearningObjective {
    var localizedTitle: String {
        switch self {
        case .businessCommunication:
            return LocalizedStrings.objectiveBusinessCommunication
        case .travelConfidence:
            return LocalizedStrings.objectiveTravelConfidence
        case .understandMovies:
            return LocalizedStrings.objectiveUnderstandMovies
        case .expandVocabulary:
            return LocalizedStrings.objectiveExpandVocabulary
        case .passExams:
            return LocalizedStrings.objectivePassExams
        case .improveSpeaking:
            return LocalizedStrings.objectiveImproveSpeaking
        case .dailyConversation:
            return LocalizedStrings.objectiveDailyConversation
        case .improveAccent:
            return LocalizedStrings.objectiveImproveAccent
        case .readingComprehension:
            return LocalizedStrings.objectiveReadingComprehension
        case .writingSkills:
            return LocalizedStrings.objectiveWritingSkills
        }
    }
}

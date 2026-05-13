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
                        .font(LumenFont.grotesk(19, weight: .semibold))
                        .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.82))
                }

                Text(objective.displayTitle)
                    .font(LumenFont.grotesk(16, weight: .semibold))
                    .foregroundStyle(LumenColors.ink100)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                            ? LumenColors.accent
                            : LumenColors.ink500,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(LumenColors.accent)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(LumenFont.grotesk(11, weight: .bold))
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
                    colors: [LumenColors.ink700, LumenColors.ink600],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(LumenColors.ink800)
    }
}

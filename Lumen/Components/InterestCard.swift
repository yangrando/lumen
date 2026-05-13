import SwiftUI

struct InterestCard: View {
    let interest: UserInterest
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(
                                isSelected
                                ? Color.white.opacity(0.18)
                                : LumenColors.ink500,
                                lineWidth: 3
                            )
                            .frame(width: 25, height: 25)

                        if isSelected {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 25, height: 25)

                            Image(systemName: "checkmark")
                                .font(LumenFont.grotesk(11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                Spacer(minLength: 8)

                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isSelected ? 0.18 : 0.06))
                            .frame(width: 72, height: 72)

                        Image(systemName: interest.icon)
                            .font(LumenFont.grotesk(30, weight: .semibold))
                            .foregroundStyle(.white.opacity(isSelected ? 0.96 : 0.82))
                    }
                    Spacer()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 0) {
                    Text(interest.displayTitle)
                        .font(LumenFont.grotesk(17, weight: .bold))
                        .foregroundStyle(isSelected ? LumenColors.ink900 : LumenColors.ink100)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 228, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(backgroundShape)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isSelected ? LumenColors.accentGlow : LumenColors.ink600,
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(
                color: isSelected ? LumenColors.gradientEnd.opacity(0.18) : Color.black.opacity(0.12),
                radius: 18,
                x: 0,
                y: 10
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var backgroundShape: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        LumenColors.accent.opacity(0.85),
                        LumenColors.info.opacity(0.7),
                        LumenColors.accent.opacity(0.80)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(LumenColors.ink800)
    }
}

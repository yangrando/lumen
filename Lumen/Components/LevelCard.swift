import SwiftUI

struct LevelCard: View {
    let level: EnglishLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.20 : 0.06))
                        .frame(width: 56, height: 56)

                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.36 : 0.10), lineWidth: 1)
                        .frame(width: 56, height: 56)

                    Text(level.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(level.shortTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text(level.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.24 : 0.10), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.20) : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0.08), radius: 18, x: 0, y: 10)
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.84), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        LumenColors.gradientStart.opacity(0.30),
                        LumenColors.gradientEnd.opacity(0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color.white.opacity(0.04))
    }
}

import SwiftUI

struct ToastView: View {
    enum Tone {
        case success
        case error

        var color: Color {
            switch self {
            case .success:
                return LumenColors.good
            case .error:
                return LumenColors.bad
            }
        }

        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.octagon.fill"
            }
        }
    }

    let title: String
    let message: String
    let tone: Tone

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: tone.icon)
                .font(LumenFont.grotesk(22, weight: .bold))
                .foregroundStyle(tone.color)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(LumenFont.grotesk(14, weight: .bold))
                    .foregroundStyle(LumenColors.ink50)

                Text(message)
                    .font(LumenFont.grotesk(13, weight: .medium))
                    .foregroundStyle(LumenColors.ink200)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LumenColors.ink800)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 10)
    }
}

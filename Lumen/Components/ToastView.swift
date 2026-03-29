import SwiftUI

struct ToastView: View {
    enum Tone {
        case success
        case error

        var color: Color {
            switch self {
            case .success:
                return Color(red: 0.10, green: 0.77, blue: 0.49)
            case .error:
                return Color(red: 0.93, green: 0.30, blue: 0.33)
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
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tone.color)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.74))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.09, green: 0.13, blue: 0.22).opacity(0.96))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 10)
    }
}

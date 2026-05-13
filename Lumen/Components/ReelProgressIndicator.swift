import SwiftUI

struct ReelProgressIndicator: View {
    let state: ReelLearningState

    private var progress: CGFloat {
        CGFloat(state.progressCount) / CGFloat(ReelLearningState.totalSteps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(LocalizedStrings.reelProgressLabel)
                    .font(LumenFont.mono(11))
                    .foregroundStyle(LumenColors.ink300)
                Text("\(state.progressCount) / \(ReelLearningState.totalSteps)")
                    .font(LumenFont.mono(11, weight: .medium))
                    .foregroundStyle(LumenColors.ink100)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LumenColors.ink700)
                    Capsule()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: max(18, geometry.size.width * progress))
                        .animation(.easeInOut(duration: 0.25), value: progress)
                }
            }
            .frame(height: 7)

            if state.isCompleted {
                Text("✔ \(LocalizedStrings.reelCompleted)")
                    .font(LumenFont.mono(11, weight: .medium))
                    .foregroundStyle(LumenColors.good)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LumenColors.ink800.opacity(0.78))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }
}
